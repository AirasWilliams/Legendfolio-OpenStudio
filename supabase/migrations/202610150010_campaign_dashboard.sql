begin;

create index if not exists legendfolio_campaign_owner_active_idx
  on public.legendfolio_campaigns(owner_id) where deleted_at is null;
create index if not exists legendfolio_membership_user_idx
  on public.legendfolio_memberships(user_id,campaign_id);
create index if not exists legendfolio_membership_review_idx
  on public.legendfolio_memberships(campaign_id,status,change_state);

-- Metadata only: full private sheets still use the existing authorised review RPCs.
create function public.legendfolio_dashboard(p_campaign_id uuid default null,p_offset integer default 0)
returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare
  u uuid:=auth.uid(); campaigns jsonb; requests jsonb; queue jsonb; total bigint;
begin
  if u is null then raise exception 'Sign in first' using errcode='42501';end if;
  if p_campaign_id is not null and not exists(
    select 1 from public.legendfolio_campaigns where id=p_campaign_id and owner_id=u and deleted_at is null
  ) then p_campaign_id:=null;end if;
  p_offset:=greatest(0,coalesce(p_offset,0));

  select coalesce(jsonb_agg(to_jsonb(x) order by x.title,x.id),'[]') into campaigns from (
    select c.id,c.title,c.game_system,c.owner_id=u as is_dm,
      case when c.owner_id=u then (select count(*) from public.legendfolio_memberships m
        where m.campaign_id=c.id and m.status='pending') else 0 end as pending_joins,
      case when c.owner_id=u then (select count(*) from public.legendfolio_memberships m
        where m.campaign_id=c.id and m.status='approved' and m.change_state='pending') else 0 end as pending_changes
    from public.legendfolio_campaigns c where c.deleted_at is null and (
      c.owner_id=u or exists(select 1 from public.legendfolio_memberships m
        where m.campaign_id=c.id and m.user_id=u and m.status='approved')
    )
  ) x;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.campaign,x.character,x.id),'[]') into requests from (
    select m.id,m.campaign_id,c.title as campaign,m.character_id,
      m.shared_summary->>'name' as character,m.status,m.change_state,
      m.submitted_revision,m.proposed_revision
    from public.legendfolio_memberships m join public.legendfolio_campaigns c on c.id=m.campaign_id
    where m.user_id=u and c.deleted_at is null
  ) x;

  select count(*) into total from public.legendfolio_memberships m
    join public.legendfolio_campaigns c on c.id=m.campaign_id
    where c.owner_id=u and c.deleted_at is null
      and (p_campaign_id is null or c.id=p_campaign_id)
      and (m.status='pending' or (m.status='approved' and m.change_state='pending'));

  select coalesce(jsonb_agg(to_jsonb(x) order by x.campaign,x.character,x.id),'[]') into queue from (
    select m.id,m.campaign_id,c.title as campaign,
      case when m.status='pending' then 'join' else 'change' end as kind,
      coalesce(m.shared_summary->>'name','Character') as character,
      coalesce(nullif(p.display_name,''),nullif(m.shared_summary->>'player',''),'Player') as player,
      m.submitted_revision,m.proposed_revision
    from public.legendfolio_memberships m join public.legendfolio_campaigns c on c.id=m.campaign_id
      left join public.legendfolio_profiles p on p.id=m.user_id
    where c.owner_id=u and c.deleted_at is null and (p_campaign_id is null or c.id=p_campaign_id)
      and (m.status='pending' or (m.status='approved' and m.change_state='pending'))
    order by c.title,coalesce(m.shared_summary->>'name','Character'),m.id
    limit 20 offset p_offset
  ) x;

  return jsonb_build_object('campaigns',campaigns,'requests',requests,'queue',queue,
    'queue_total',total,'queue_campaign_id',p_campaign_id,'offset',p_offset,'limit',20,'checked_at',now());
end $$;

revoke all on function public.legendfolio_dashboard(uuid,integer) from public,anon;
grant execute on function public.legendfolio_dashboard(uuid,integer) to authenticated;
commit;
