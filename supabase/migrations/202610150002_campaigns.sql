begin;
create table public.legendfolio_campaigns(id uuid primary key default gen_random_uuid(),owner_id uuid not null references auth.users(id),title text not null check(length(title) between 1 and 160),description text not null default '',game_system text not null default 'dnd5e',settings jsonb not null default '{}',created_at timestamptz not null default now());
create table public.legendfolio_invites(id uuid primary key default gen_random_uuid(),campaign_id uuid not null references public.legendfolio_campaigns(id) on delete cascade,code text unique not null,expires_at timestamptz not null,usage_limit int check(usage_limit>0),uses int not null default 0,revoked boolean not null default false);
create table public.legendfolio_memberships(id uuid primary key default gen_random_uuid(),campaign_id uuid not null references public.legendfolio_campaigns(id) on delete cascade,user_id uuid not null references auth.users(id),character_id uuid references public.legendfolio_characters(id) on delete set null,status text not null default 'pending' check(status in ('pending','approved','rejected')),party_role text not null default '',shared_summary jsonb not null default '{}',unique(campaign_id,user_id,character_id));
create table public.legendfolio_invite_attempts(user_id uuid primary key references auth.users(id),attempts int not null default 0,window_start timestamptz not null default now());
create table public.legendfolio_campaign_events(id bigint generated always as identity primary key,campaign_id uuid not null references public.legendfolio_campaigns(id),actor_id uuid not null,event text not null,created_at timestamptz not null default now());
-- No direct writes. Only the authenticated, validated RPC may mutate campaign state.
alter table public.legendfolio_campaigns enable row level security;
alter table public.legendfolio_invites enable row level security;
alter table public.legendfolio_memberships enable row level security;
alter table public.legendfolio_invite_attempts enable row level security;
alter table public.legendfolio_campaign_events enable row level security;
revoke all on public.legendfolio_campaigns,public.legendfolio_invites,public.legendfolio_memberships,public.legendfolio_invite_attempts,public.legendfolio_campaign_events from anon,authenticated;
create function public.legendfolio_campaign_action(p_action text,p_payload jsonb default '{}') returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare u uuid:=auth.uid(); c public.legendfolio_campaigns; i public.legendfolio_invites; m public.legendfolio_memberships; ch public.legendfolio_characters; result jsonb; n int;
begin
if u is null then raise exception 'Sign in first' using errcode='42501'; end if;
if p_action='create' then
 insert into public.legendfolio_campaigns(owner_id,title,description,game_system,settings) values(u,left(trim(p_payload->>'title'),160),left(coalesce(p_payload->>'description',''),10000),left(coalesce(p_payload->>'game_system','dnd5e'),80),coalesce(p_payload->'settings','{}')) returning * into c;
 insert into public.legendfolio_campaign_events(campaign_id,actor_id,event) values(c.id,u,'Campaign created');return to_jsonb(c);
end if;
if p_action='list' then return coalesce((select jsonb_agg(to_jsonb(x)) from (select ca.*,ca.owner_id=u as is_dm from public.legendfolio_campaigns ca where ca.owner_id=u or exists(select 1 from public.legendfolio_memberships mm where mm.campaign_id=ca.id and mm.user_id=u and mm.status='approved') order by ca.created_at desc)x),'[]');end if;
if p_action in ('preview','join') then
 insert into public.legendfolio_invite_attempts(user_id) values(u) on conflict do nothing;
 select attempts into n from public.legendfolio_invite_attempts where user_id=u for update;
 update public.legendfolio_invite_attempts set attempts=case when window_start<now()-interval '15 minutes' then 1 else attempts+1 end,window_start=case when window_start<now()-interval '15 minutes' then now() else window_start end where user_id=u returning attempts into n;
 if n>20 then return jsonb_build_object('error','Too many attempts. Try again in 15 minutes.');end if;
 select * into i from public.legendfolio_invites where code=upper(trim(p_payload->>'code')) for update;
 if i.id is null or i.revoked or i.expires_at<=now() or (i.usage_limit is not null and i.uses>=i.usage_limit) then return jsonb_build_object('error','Invitation invalid, expired, revoked or fully used.');end if;
 select * into c from public.legendfolio_campaigns where id=i.campaign_id;
 if p_action='preview' then return jsonb_build_object('id',c.id,'title',c.title,'description',c.description,'game_system',c.game_system);end if;
 if c.owner_id=u then raise exception 'You already own this campaign';end if;
 select * into ch from public.legendfolio_characters where id=(p_payload->>'character_id')::uuid and owner_id=u;
 if ch.id is null then raise exception 'Choose your own cloud character' using errcode='42501';end if;
 insert into public.legendfolio_memberships(campaign_id,user_id,character_id,party_role,shared_summary) values(c.id,u,ch.id,left(coalesce(p_payload->>'party_role',''),80),jsonb_build_object('name',ch.character_name,'player',coalesce((select display_name from public.legendfolio_profiles where id=u),''),'class',ch.character_data#>>'{fields,ClassLevel}','portrait',ch.character_data#>>'{art,portrait}')) on conflict(campaign_id,user_id,character_id) do nothing returning * into m;
 if m.id is null then return jsonb_build_object('error','This character already has a request.');end if;
 update public.legendfolio_invites set uses=uses+1 where id=i.id;
 insert into public.legendfolio_campaign_events(campaign_id,actor_id,event) values(c.id,u,'Character requested membership');return to_jsonb(m);
end if;
select * into c from public.legendfolio_campaigns where id=(p_payload->>'campaign_id')::uuid;
if c.id is null then raise exception 'Campaign unavailable' using errcode='42501';end if;
if p_action='roster' then
 if c.owner_id<>u and not exists(select 1 from public.legendfolio_memberships where campaign_id=c.id and user_id=u and status='approved') then raise exception 'Access denied' using errcode='42501';end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',mm.id,'status',mm.status,'party_role',mm.party_role,'summary',mm.shared_summary)) from public.legendfolio_memberships mm where mm.campaign_id=c.id and (c.owner_id=u or mm.status='approved')),'[]');end if;
if c.owner_id<>u then raise exception 'Only the campaign DM can do this' using errcode='42501';end if;
if p_action='invite' then
 insert into public.legendfolio_invites(campaign_id,code,expires_at,usage_limit) values(c.id,upper(replace(gen_random_uuid()::text,'-','')),now()+make_interval(hours=>greatest(1,least(720,coalesce((p_payload->>'hours')::int,168)))),nullif(p_payload->>'usage_limit','')::int) returning * into i;return to_jsonb(i);
elsif p_action='invites' then return coalesce((select jsonb_agg(to_jsonb(ii)) from public.legendfolio_invites ii where ii.campaign_id=c.id),'[]');
elsif p_action='revoke' then update public.legendfolio_invites set revoked=true where id=(p_payload->>'invite_id')::uuid and campaign_id=c.id;
elsif p_action='review' then
 if p_payload->>'status' not in ('approved','rejected') then raise exception 'Invalid decision';end if;
 update public.legendfolio_memberships set status=p_payload->>'status' where id=(p_payload->>'membership_id')::uuid and campaign_id=c.id;
else raise exception 'Unknown campaign action';end if;
insert into public.legendfolio_campaign_events(campaign_id,actor_id,event) values(c.id,u,p_action);return jsonb_build_object('ok',true);
end $$;
revoke all on function public.legendfolio_campaign_action(text,jsonb) from public,anon;
grant execute on function public.legendfolio_campaign_action(text,jsonb) to authenticated;
commit;
