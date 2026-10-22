begin;
create table public.legendfolio_party_state(
 membership_id uuid primary key references public.legendfolio_memberships(id),campaign_id uuid not null references public.legendfolio_campaigns(id),
 known boolean not null default false,max_hp integer not null default 0 check(max_hp between 0 and 999999),hp integer not null default 0 check(hp>=0),temp_hp integer not null default 0 check(temp_hp between 0 and 999999),
 conditions jsonb not null default '[]',concentration text not null default '',revision bigint not null default 1,updated_at timestamptz not null default now(),check(hp<=max_hp)
);
create index legendfolio_party_campaign_idx on public.legendfolio_party_state(campaign_id);
create table public.legendfolio_party_changes(
 id bigint generated always as identity primary key,membership_id uuid not null references public.legendfolio_memberships(id),campaign_id uuid not null references public.legendfolio_campaigns(id),actor_id uuid not null,
 request_id uuid not null,payload jsonb not null,previous_state jsonb not null,next_state jsonb not null,created_at timestamptz not null default now(),unique(actor_id,request_id)
);
create index legendfolio_party_history_idx on public.legendfolio_party_changes(membership_id,id desc);
alter table public.legendfolio_party_state enable row level security;alter table public.legendfolio_party_changes enable row level security;
revoke all on public.legendfolio_party_state,public.legendfolio_party_changes from public,anon,authenticated;
create function public.legendfolio_seed_party() returns trigger language plpgsql security definer set search_path=pg_catalog,public as $$
declare maxhp integer;currenthp integer;temphp integer;known boolean;seed_conditions jsonb;seed_concentration text;
begin
 if new.status<>'approved' then return new;end if;
 known:=coalesce(new.review_snapshot#>>'{fields,HPMax}','')~'^\d{1,6}$';
 maxhp:=case when known then (new.review_snapshot#>>'{fields,HPMax}')::integer else 0 end;
 currenthp:=case when coalesce(new.review_snapshot#>>'{fields,HPCurrent}','')~'^\d{1,6}$' then (new.review_snapshot#>>'{fields,HPCurrent}')::integer else maxhp end;
 temphp:=case when coalesce(new.review_snapshot#>>'{fields,HPTemp}','')~'^\d{1,6}$' then (new.review_snapshot#>>'{fields,HPTemp}')::integer else 0 end;
 select coalesce(jsonb_agg(value),'[]') into seed_conditions from (select distinct trim(value#>>'{}') as value from jsonb_array_elements(case when jsonb_typeof(new.review_snapshot#>'{live,conditions}')='array' then new.review_snapshot#>'{live,conditions}' else '[]'::jsonb end) where jsonb_typeof(value)='string' and length(trim(value#>>'{}')) between 1 and 60 limit 20)x;
 seed_concentration:=left(coalesce(new.review_snapshot#>>'{live,concentration}',''),160);
 if exists(select 1 from jsonb_array_elements_text(seed_conditions) x where lower(x) in ('incapacitated','paralyzed','petrified','stunned','unconscious')) then seed_concentration:='';end if;
 insert into public.legendfolio_party_state(membership_id,campaign_id,known,max_hp,hp,temp_hp,conditions,concentration) values(new.id,new.campaign_id,known,maxhp,least(maxhp,currenthp),temphp,seed_conditions,seed_concentration) on conflict do nothing;
 return new;
end $$;
revoke all on function public.legendfolio_seed_party() from public,anon,authenticated;
create trigger legendfolio_party_seed after insert or update on public.legendfolio_memberships for each row execute function public.legendfolio_seed_party();
-- Existing approved members gain an independent gameplay record; approved sheets are unchanged.
update public.legendfolio_memberships set status=status where status='approved';

create function public.legendfolio_party(p_action text,p_campaign_id uuid,p_payload jsonb default '{}') returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
#variable_conflict use_variable
declare u uuid:=auth.uid();c public.legendfolio_campaigns;m public.legendfolio_memberships;s public.legendfolio_party_state;prior public.legendfolio_party_state;event public.legendfolio_party_changes;is_dm boolean;request uuid;result jsonb;conditions jsonb;concentration text;maximum integer;hp integer;temporary integer;amount integer;known boolean;visibility text;show_conditions boolean;can_see boolean;
begin
 if u is null then raise exception 'Sign in first' using errcode='42501';end if;
 select * into c from public.legendfolio_campaigns where id=p_campaign_id and deleted_at is null for share;
 if c.id is null then raise exception 'Campaign unavailable' using errcode='42501';end if;
 is_dm:=c.owner_id=u;
 if not is_dm and not exists(select 1 from public.legendfolio_memberships where campaign_id=c.id and user_id=u and status='approved') then raise exception 'Approved campaign membership required' using errcode='42501';end if;
 visibility:=coalesce(c.settings->>'party_hp_visibility','exact');show_conditions:=coalesce((c.settings->>'party_conditions_visible')::boolean,true);
 if p_action='list' then
  select coalesce(jsonb_agg(to_jsonb(x) order by x.name,x.membership_id),'[]') into result from (
   select mm.id as membership_id,mm.character_id,coalesce(nullif(mm.shared_summary->>'name',''),'Character') as name,
    case when is_dm or mm.user_id=u or coalesce(c.settings->>'roster_visibility','party')='party' then coalesce(mm.shared_summary->>'player','') else '' end as player,
    case when is_dm or mm.user_id=u or coalesce(c.settings->>'roster_visibility','party')='party' then coalesce(mm.shared_summary->>'class','') else '' end as class,
    mm.user_id=u as is_own,(is_dm or mm.user_id=u) as can_edit,st.revision,st.updated_at,st.known,
    case when is_dm or mm.user_id=u or visibility='exact' then st.hp else null end as hp,
    case when is_dm or mm.user_id=u or visibility='exact' then st.max_hp else null end as max_hp,
    case when is_dm or mm.user_id=u or visibility='exact' then st.temp_hp else null end as temp_hp,
    case when not (is_dm or mm.user_id=u) and visibility='hidden' then 'Private' when not st.known then 'Untracked' when st.hp=0 then 'At 0 HP' when st.hp=st.max_hp then 'Healthy' else 'Wounded' end as health_status,
    case when is_dm or mm.user_id=u or show_conditions then st.conditions else '[]'::jsonb end as conditions,
    case when is_dm or mm.user_id=u or show_conditions then st.concentration else null end as concentration
   from public.legendfolio_memberships mm join public.legendfolio_party_state st on st.membership_id=mm.id where mm.campaign_id=c.id and mm.status='approved'
  )x;
  return jsonb_build_object('campaign',c.title,'is_dm',is_dm,'members',result,'hp_visibility',visibility,'conditions_visible',show_conditions,'checked_at',now());
 end if;
 if p_action='visibility' then
  if not is_dm then raise exception 'Only the DM can change visibility' using errcode='42501';end if;
  if p_payload->>'hp_visibility' is null or p_payload->>'hp_visibility' not in ('exact','status','hidden') or jsonb_typeof(p_payload->'conditions_visible') is distinct from 'boolean' then raise exception 'Choose valid visibility settings';end if;
  update public.legendfolio_campaigns set settings=settings||jsonb_build_object('party_hp_visibility',p_payload->>'hp_visibility','party_conditions_visible',p_payload->'conditions_visible') where id=c.id;
  return jsonb_build_object('ok',true);
 end if;
 if p_action not in ('replace','damage','heal','temp','clear_temp','history') or p_action is null then raise exception 'Unknown party action';end if;
 select * into m from public.legendfolio_memberships where id=(p_payload->>'membership_id')::uuid and campaign_id=c.id and status='approved' for share;
 if m.id is null or (not is_dm and m.user_id<>u) then raise exception 'Only your own character or the DM can change this status' using errcode='42501';end if;
 if p_action='history' then return coalesce((select jsonb_agg(to_jsonb(x) order by x.id desc) from (select id,previous_state,next_state,created_at,case when actor_id=u then 'You' when actor_id=c.owner_id then 'Dungeon Master' else 'Player' end as actor from public.legendfolio_party_changes where membership_id=m.id order by id desc limit 20)x),'[]');end if;
 request:=(p_payload->>'request_id')::uuid;if request is null then raise exception 'A change request ID is required';end if;
 perform pg_advisory_xact_lock(hashtextextended(u::text||request::text,0));
 select * into s from public.legendfolio_party_state where membership_id=m.id for update;
 if s.membership_id is null then raise exception 'Party status unavailable';end if;
 select * into event from public.legendfolio_party_changes where actor_id=u and request_id=request;
 if event.id is not null then
  if event.membership_id<>m.id or event.payload<>p_payload||jsonb_build_object('action',p_action) then raise exception 'This request belongs to another change';end if;
  return jsonb_build_object('state',event.next_state,'current_state',to_jsonb(s),'replayed',true);
 end if;
 if (p_payload->>'revision')::bigint is null or (p_payload->>'revision')::bigint<>s.revision then raise exception 'Party status changed on another device. Review the latest status before sending your changes.' using errcode='40001';end if;
 prior:=s;maximum:=s.max_hp;hp:=s.hp;temporary:=s.temp_hp;conditions:=s.conditions;concentration:=s.concentration;known:=s.known;
 if p_action='replace' then
  if jsonb_typeof(p_payload->'state') is distinct from 'object' then raise exception 'Status data required';end if;
  maximum:=(p_payload#>>'{state,max_hp}')::integer;hp:=(p_payload#>>'{state,hp}')::integer;temporary:=(p_payload#>>'{state,temp_hp}')::integer;
  conditions:=p_payload#>'{state,conditions}';concentration:=coalesce(p_payload#>>'{state,concentration}','');known:=coalesce((p_payload#>>'{state,known}')::boolean,true);
 else
  if not known then raise exception 'Set maximum HP before applying health changes';end if;
  amount:=coalesce((p_payload->>'amount')::integer,0);if amount not between 0 and 999999 then raise exception 'Use a valid amount';end if;
  if p_action='damage' then hp:=greatest(0,hp-greatest(0,amount-temporary));temporary:=greatest(0,temporary-amount);
  elsif p_action='heal' then hp:=least(maximum,hp+amount);
  elsif p_action='temp' then temporary:=greatest(temporary,amount);
  elsif p_action='clear_temp' then temporary:=0;end if;
 end if;
 if s.known and not known then raise exception 'A tracked character cannot be changed to untracked';end if;
 if not known and (maximum<>0 or hp<>0) then raise exception 'Untracked health must not contain HP totals';end if;
 if maximum is null or hp is null or temporary is null or maximum not between 0 and 999999 or hp not between 0 and maximum or temporary not between 0 and 999999 or length(concentration)>160 then raise exception 'Use valid HP and concentration values';end if;
 if jsonb_typeof(conditions) is distinct from 'array' then raise exception 'Conditions must be a list';end if;
 if jsonb_array_length(conditions)>20 or exists(select 1 from jsonb_array_elements(conditions) x where jsonb_typeof(x)<>'string' or length(trim(x#>>'{}')) not between 1 and 60) then raise exception 'Use up to 20 conditions, each 1 to 60 characters';end if;
 select coalesce(jsonb_agg(value order by value),'[]') into conditions from (select distinct trim(value) as value from jsonb_array_elements_text(conditions))x;
 if exists(select 1 from jsonb_array_elements_text(conditions) x where lower(x) in ('incapacitated','paralyzed','petrified','stunned','unconscious')) then concentration:='';end if;
 update public.legendfolio_party_state set known=known,max_hp=maximum,hp=hp,temp_hp=temporary,conditions=conditions,concentration=concentration,revision=revision+1,updated_at=now() where membership_id=m.id returning * into s;
 insert into public.legendfolio_party_changes(membership_id,campaign_id,actor_id,request_id,payload,previous_state,next_state) values(m.id,c.id,u,request,p_payload||jsonb_build_object('action',p_action),to_jsonb(prior),to_jsonb(s));
 insert into public.legendfolio_activity(campaign_id,recipient_id,actor_id,kind,message) values(c.id,m.user_id,u,'party_status',coalesce(m.shared_summary->>'name','Character')||' updated party health or status.');
 return jsonb_build_object('state',to_jsonb(s),'current_state',to_jsonb(s),'replayed',false);
end $$;
revoke all on function public.legendfolio_party(text,uuid,jsonb) from public,anon;
grant execute on function public.legendfolio_party(text,uuid,jsonb) to authenticated;
commit;
