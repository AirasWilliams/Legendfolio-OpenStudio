begin;
-- A separate feed prevents generic campaign logs from exposing private review actions.
create table public.legendfolio_activity (
 id bigint generated always as identity primary key,
 campaign_id uuid not null references public.legendfolio_campaigns(id),
 recipient_id uuid, actor_id uuid not null, kind text not null,
 message text not null, created_at timestamptz not null default now()
);
create index legendfolio_activity_campaign_idx on public.legendfolio_activity(campaign_id,id desc);
create table public.legendfolio_activity_reads (
 user_id uuid not null references auth.users(id),campaign_id uuid not null references public.legendfolio_campaigns(id),
 through_id bigint not null default 0,primary key(user_id,campaign_id)
);
alter table public.legendfolio_activity enable row level security;
alter table public.legendfolio_activity_reads enable row level security;
revoke all on public.legendfolio_activity,public.legendfolio_activity_reads from public,anon,authenticated;

create function public.legendfolio_record_activity() returns trigger language plpgsql security definer set search_path=pg_catalog,public as $$
declare message text; kind text; label text;
begin
 if tg_table_name='legendfolio_memberships' then
  label:=left(coalesce(nullif(new.shared_summary->>'name',''),'Character'),160);
  if tg_op='INSERT' then kind:='submission';message:=label||' was submitted for membership.';
  elsif new.status is distinct from old.status then
   kind:='membership';message:=label||case new.status when 'approved' then ' was approved for the campaign.' when 'rejected' then ' had membership declined or ended.' else ' was resubmitted for membership.' end;
  elsif new.change_state is distinct from old.change_state and new.change_state in ('pending','approved','rejected') then
   kind:='character_change';message:=label||case new.change_state when 'pending' then ' submitted character changes for review.' when 'approved' then ' had character changes approved.' else ' had character changes rejected.' end;
  else return new;end if;
  insert into public.legendfolio_activity(campaign_id,recipient_id,actor_id,kind,message) values(new.campaign_id,new.user_id,coalesce(auth.uid(),new.user_id),kind,message);
 else
  if new.settings is not distinct from old.settings and new.title is not distinct from old.title and new.description is not distinct from old.description then return new;end if;
  insert into public.legendfolio_activity(campaign_id,actor_id,kind,message) values(new.id,coalesce(auth.uid(),new.owner_id),'campaign_update','The DM updated the campaign details or rules.');
 end if;
 return new;
end $$;
revoke all on function public.legendfolio_record_activity() from public,anon,authenticated;
create trigger legendfolio_membership_activity after insert or update on public.legendfolio_memberships for each row execute function public.legendfolio_record_activity();
create trigger legendfolio_campaign_activity after update on public.legendfolio_campaigns for each row execute function public.legendfolio_record_activity();

create function public.legendfolio_activity_feed(p_campaign_id uuid default null,p_before bigint default null,p_mark_through bigint default null,p_announcement text default null) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare u uuid:=auth.uid();result jsonb; latest bigint; body text;
begin
 if u is null then raise exception 'Sign in first' using errcode='42501';end if;
 if p_announcement is not null then
  if p_campaign_id is null or not exists(select 1 from public.legendfolio_campaigns where id=p_campaign_id and owner_id=u and deleted_at is null) then raise exception 'Only the campaign DM can post updates' using errcode='42501';end if;
  body:=trim(p_announcement);if length(body)<1 or length(body)>2000 then raise exception 'Updates must contain 1 to 2000 characters';end if;
  insert into public.legendfolio_activity(campaign_id,actor_id,kind,message) values(p_campaign_id,u,'announcement',body);
 end if;
 -- Accessible rows include DM reviews, the player's own review events, and shared updates for approved members.
 if p_mark_through is not null then
  if p_campaign_id is null then raise exception 'Choose a campaign to mark read';end if;
  select max(a.id) into latest from public.legendfolio_activity a join public.legendfolio_campaigns c on c.id=a.campaign_id
   where c.id=p_campaign_id and c.deleted_at is null and a.id<=p_mark_through and (c.owner_id=u or a.recipient_id=u or (a.recipient_id is null and exists(select 1 from public.legendfolio_memberships m where m.campaign_id=c.id and m.user_id=u and m.status='approved')));
  if latest is null then raise exception 'Activity unavailable' using errcode='42501';end if;
  insert into public.legendfolio_activity_reads(user_id,campaign_id,through_id) values(u,p_campaign_id,latest) on conflict(user_id,campaign_id) do update set through_id=greatest(legendfolio_activity_reads.through_id,excluded.through_id);
 end if;
 with visible as (
 select a.id,a.campaign_id,c.title as campaign,a.kind,a.message,a.created_at,
 a.actor_id<>u and a.id>coalesce(r.through_id,0) as unread
 from public.legendfolio_activity a join public.legendfolio_campaigns c on c.id=a.campaign_id
 left join public.legendfolio_activity_reads r on r.campaign_id=c.id and r.user_id=u
 where c.deleted_at is null and (p_campaign_id is null or c.id=p_campaign_id)
 and (c.owner_id=u or a.recipient_id=u or (a.recipient_id is null and exists(select 1 from public.legendfolio_memberships m where m.campaign_id=c.id and m.user_id=u and m.status='approved')))
 ), page as (select * from visible where p_before is null or id<p_before order by id desc limit 20)
 select jsonb_build_object('items',coalesce((select jsonb_agg(to_jsonb(p) order by id desc) from page p),'[]'),
 'unread',(select count(*) from visible where unread),'checked_at',now()) into result;
 return result;
end $$;
revoke all on function public.legendfolio_activity_feed(uuid,bigint,bigint,text) from public,anon;
grant execute on function public.legendfolio_activity_feed(uuid,bigint,bigint,text) to authenticated;
commit;
