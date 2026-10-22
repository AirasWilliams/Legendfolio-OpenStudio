-- Campaign foundation: canonical settings/policy, owner-only secrets, revisioned recovery.
-- Existing campaigns and approved character snapshots are retained.
begin;
create table public.legendfolio_campaign_config (
 campaign_id uuid primary key references public.legendfolio_campaigns(id) on delete cascade,
 configuration jsonb not null default '{}' check(jsonb_typeof(configuration)='object'),
 private_notes text not null default '' check(length(private_notes)<=30000),
 elapsed_days integer not null default 0 check(elapsed_days between 0 and 10000000),
 revision bigint not null default 1 check(revision>0),updated_at timestamptz not null default now()
);
create table public.legendfolio_campaign_config_history (
 campaign_id uuid not null references public.legendfolio_campaigns(id) on delete cascade,
 revision bigint not null,snapshot jsonb not null,actor_id uuid not null references auth.users(id),
 action text not null,created_at timestamptz not null default now(),primary key(campaign_id,revision)
);
create table public.legendfolio_campaign_config_operations (
 owner_id uuid not null references auth.users(id),operation_id uuid not null,
 request jsonb not null,result jsonb not null,created_at timestamptz not null default now(),primary key(owner_id,operation_id)
);
alter table public.legendfolio_campaign_config enable row level security;
alter table public.legendfolio_campaign_config force row level security;
alter table public.legendfolio_campaign_config_history enable row level security;
alter table public.legendfolio_campaign_config_history force row level security;
alter table public.legendfolio_campaign_config_operations enable row level security;
alter table public.legendfolio_campaign_config_operations force row level security;
revoke all on public.legendfolio_campaign_config,public.legendfolio_campaign_config_history,public.legendfolio_campaign_config_operations from public,anon,authenticated;

-- No private data is stored in campaigns.settings, which existing member APIs return.
create function public.legendfolio_campaign_foundation_snapshot(p_campaign uuid) returns jsonb
language sql stable security definer set search_path=pg_catalog,public as $$
 select jsonb_build_object('campaign_id',c.id,'owner_id',c.owner_id,'revision',coalesce(f.revision,0),
  'fingerprint',md5(jsonb_build_object('title',c.title,'description',c.description,'game_system',c.game_system,'settings',c.settings,'rules',coalesce(to_jsonb(r),'{}'),'foundation_revision',coalesce(f.revision,0))::text),
  'title',c.title,'description',c.description,'game_system',c.game_system,
  'roster_visibility',coalesce(c.settings->>'roster_visibility','party'),
  'hp_visibility',coalesce(c.settings->>'party_hp_visibility','exact'),
  'conditions_visible',coalesce(c.settings->'party_conditions_visible','true'::jsonb),
  'editions',coalesce(r.editions,'["2014","2024"]'::jsonb),'allow_custom',coalesce(r.allow_custom,true),
  'policy_revision',coalesce(r.revision,0),'configuration',coalesce(f.configuration,'{}'::jsonb),
  'private_notes',coalesce(f.private_notes,''),'elapsed_days',coalesce(f.elapsed_days,0),'updated_at',f.updated_at)
 from public.legendfolio_campaigns c left join public.legendfolio_campaign_config f on f.campaign_id=c.id
 left join public.legendfolio_builder_rules r on r.campaign_id=c.id where c.id=p_campaign and c.deleted_at is null
$$;
revoke all on function public.legendfolio_campaign_foundation_snapshot(uuid) from public,anon,authenticated;

create function public.legendfolio_campaign_foundation(p_action text,p_campaign uuid default null,p_expected_revision bigint default null,p_fingerprint text default null,p_data jsonb default '{}',p_operation uuid default null) returns jsonb
language plpgsql security definer set search_path=pg_catalog,public as $$
declare u uuid:=auth.uid();c public.legendfolio_campaigns;f public.legendfolio_campaign_config;old_operation public.legendfolio_campaign_config_operations;
 current_snapshot jsonb;result jsonb;request jsonb;payload jsonb:=p_data;configuration jsonb;editions jsonb;default_edition text;k text;n integer;first_session uuid;action_name text:=p_action;
begin
 if u is null then raise exception 'Sign in first' using errcode='42501';end if;
 if p_action not in ('create','get','context','history','save','restore','advance_day') or p_action is null then raise exception 'Unknown campaign foundation action' using errcode='22023';end if;
 if jsonb_typeof(p_data) is distinct from 'object' or octet_length(p_data::text)>100000 then raise exception 'Invalid campaign foundation data' using errcode='22023';end if;
 if p_action in ('create','save','restore','advance_day') then
  if p_operation is null then raise exception 'A unique request id is required' using errcode='22023';end if;
  request:=jsonb_build_object('action',p_action,'campaign',p_campaign,'revision',p_expected_revision,'fingerprint',p_fingerprint,'data',p_data);
  perform pg_advisory_xact_lock(hashtextextended(u::text||p_operation::text,0));
  select * into old_operation from public.legendfolio_campaign_config_operations where owner_id=u and operation_id=p_operation;
  if old_operation.operation_id is not null then
   -- Recheck ownership/deletion even on replay, before returning a private snapshot.
   if old_operation.request<>request then raise exception 'Request id was reused with different data' using errcode='22023';end if;
   if not exists(select 1 from public.legendfolio_campaigns where id=(old_operation.result->>'campaign_id')::uuid and owner_id=u and deleted_at is null) then raise exception 'Campaign unavailable' using errcode='42501';end if;
   return old_operation.result;
  end if;
 end if;
 if p_action<>'create' then
  if p_action in ('save','restore','advance_day') then
   -- Same advisory lock as migration016 policy writes; row lock also serialises legacy settings writes.
   perform pg_advisory_xact_lock(hashtextextended(p_campaign::text,0));
   select * into c from public.legendfolio_campaigns where id=p_campaign and deleted_at is null for update;
  else select * into c from public.legendfolio_campaigns where id=p_campaign and deleted_at is null;end if;
  if c.id is null then raise exception 'Campaign unavailable' using errcode='42501';end if;
  if p_action='context' then
   if c.owner_id<>u and not exists(select 1 from public.legendfolio_memberships where campaign_id=c.id and user_id=u and status in ('approved','pending')) then raise exception 'Campaign unavailable' using errcode='42501';end if;
   result:=public.legendfolio_campaign_foundation_snapshot(c.id);
   -- Explicit safe projection: never return owner notes/history, future config keys or operation payloads.
   return jsonb_build_object('campaign_id',c.id,'title',c.title,'description',c.description,'editions',result->'editions','allow_custom',result->'allow_custom',
    'revision',result->'revision','elapsed_days',result->'elapsed_days','configuration',jsonb_build_object('default_edition',result#>'{configuration,default_edition}',
    'setting',result#>'{configuration,setting}','tone',result#>'{configuration,tone}','cadence',result#>'{configuration,cadence}','table_agreement',result#>'{configuration,table_agreement}',
    'ability_method',result#>'{configuration,ability_method}','source',result#>'{configuration,source}'));
  end if;
  if c.owner_id<>u then raise exception 'Only the authenticated campaign owner can manage this campaign' using errcode='42501';end if;
  current_snapshot:=public.legendfolio_campaign_foundation_snapshot(c.id);
  if p_action='get' then return current_snapshot;end if;
  if p_action='history' then return coalesce((select jsonb_agg(to_jsonb(x)) from(select revision,action,snapshot,created_at from public.legendfolio_campaign_config_history where campaign_id=c.id order by revision desc limit 50)x),'[]');end if;
  if p_expected_revision is distinct from (current_snapshot->>'revision')::bigint or p_fingerprint is distinct from current_snapshot->>'fingerprint' then raise exception 'Campaign changed on another device. Reload before saving.' using errcode='40001';end if;
  if p_action='restore' then
   if jsonb_typeof(p_data->'revision') is distinct from 'number' or p_data->>'revision' !~ '^\d+$' then raise exception 'Choose a historical revision' using errcode='22023';end if;
   select snapshot into payload from public.legendfolio_campaign_config_history where campaign_id=c.id and revision=(p_data->>'revision')::bigint;
   if payload is null then raise exception 'Historical campaign revision unavailable' using errcode='22023';end if;
  end if;
 end if;
 if p_action='advance_day' then
  n:=(current_snapshot->>'elapsed_days')::int+1;
  if n>10000000 then raise exception 'Calendar limit reached' using errcode='22023';end if;
  insert into public.legendfolio_campaign_config(campaign_id,elapsed_days,revision) values(c.id,n,1)
   on conflict(campaign_id) do update set elapsed_days=n,revision=legendfolio_campaign_config.revision+1,updated_at=now();
 else
  if jsonb_typeof(payload->'title') is distinct from 'string' or length(trim(payload->>'title')) not between 1 and 160 then raise exception 'Enter a campaign name (1 to 160 characters)' using errcode='22023';end if;
  if length(coalesce(payload->>'description',''))>10000 or length(coalesce(payload->>'private_notes',''))>30000 then raise exception 'Campaign notes exceed the allowed length' using errcode='22023';end if;
  editions:=payload->'editions';
  if jsonb_typeof(editions) is distinct from 'array' then raise exception 'Choose allowed rules editions' using errcode='22023';end if;
  if jsonb_array_length(editions) not between 1 and 2 or exists(select 1 from jsonb_array_elements(editions) x where jsonb_typeof(x)<>'string' or x#>>'{}' not in ('2014','2024')) or (select count(*)<>count(distinct value) from jsonb_array_elements(editions)) then raise exception 'Choose valid, unique rules editions' using errcode='22023';end if;
  configuration:=coalesce(payload->'configuration','{}');
  if jsonb_typeof(configuration) is distinct from 'object' then raise exception 'Invalid campaign configuration' using errcode='22023';end if;
  default_edition:=configuration->>'default_edition';
  if default_edition is null or not(editions ? default_edition) then raise exception 'The default rules edition must be allowed' using errcode='22023';end if;
  if payload->>'roster_visibility' not in ('party','names') or payload->>'roster_visibility' is null or payload->>'hp_visibility' not in ('exact','status','hidden') or payload->>'hp_visibility' is null then raise exception 'Choose valid party visibility' using errcode='22023';end if;
  if jsonb_typeof(payload->'conditions_visible') is distinct from 'boolean' or jsonb_typeof(payload->'allow_custom') is distinct from 'boolean' then raise exception 'Choose valid campaign permissions' using errcode='22023';end if;
  if configuration->>'ability_method' not in ('standard-array','point-buy','rolled','discuss') or configuration->>'ability_method' is null then raise exception 'Choose an ability generation preference' using errcode='22023';end if;
  for k in select unnest(array['setting','tone','cadence','table_agreement']) loop
   if configuration ? k and (jsonb_typeof(configuration->k)<>'string' or length(configuration->>k)>case when k='table_agreement' then 10000 else 500 end) then raise exception 'A campaign field exceeds its limit' using errcode='22023';end if;
  end loop;
  -- Store only understood public configuration. Source is fixed to the official open SRD foundation.
  configuration:=jsonb_build_object('default_edition',default_edition,'setting',coalesce(configuration->>'setting','Original world'),
   'tone',coalesce(configuration->>'tone','Adventure'),'cadence',coalesce(configuration->>'cadence','To be agreed'),
   'table_agreement',coalesce(configuration->>'table_agreement',''),'ability_method',configuration->>'ability_method',
   'source',case default_edition when '2014' then 'SRD 5.1' else 'SRD 5.2.1' end,'approval_required',true);
  if payload ? 'elapsed_days' and (jsonb_typeof(payload->'elapsed_days')<>'number' or payload->>'elapsed_days' !~ '^\d+$') then raise exception 'Calendar day must be a whole number' using errcode='22023';end if;
  n:=coalesce((payload->>'elapsed_days')::int,0);if n not between 0 and 10000000 then raise exception 'Calendar day is outside the supported range' using errcode='22023';end if;
  if p_action='create' then
   if p_campaign is not null or p_expected_revision is not null or p_fingerprint is not null then raise exception 'New campaigns cannot replace an existing campaign' using errcode='22023';end if;
   insert into public.legendfolio_campaigns(owner_id,title,description,game_system) values(u,trim(payload->>'title'),coalesce(payload->>'description',''),'dnd5e') returning * into c;
  end if;
  update public.legendfolio_campaigns set title=trim(payload->>'title'),description=coalesce(payload->>'description',''),game_system='dnd5e',
   settings=settings||jsonb_build_object('roster_visibility',payload->>'roster_visibility','party_hp_visibility',payload->>'hp_visibility','party_conditions_visible',(payload->>'conditions_visible')::boolean) where id=c.id;
  insert into public.legendfolio_builder_rules(campaign_id,editions,allow_custom,revision) values(c.id,editions,(payload->>'allow_custom')::boolean,1)
   on conflict(campaign_id) do update set editions=excluded.editions,allow_custom=excluded.allow_custom,revision=case when row(legendfolio_builder_rules.editions,legendfolio_builder_rules.allow_custom) is distinct from row(excluded.editions,excluded.allow_custom) then legendfolio_builder_rules.revision+1 else legendfolio_builder_rules.revision end,updated_at=now();
  insert into public.legendfolio_campaign_config(campaign_id,configuration,private_notes,elapsed_days,revision) values(c.id,configuration,coalesce(payload->>'private_notes',''),n,1)
   on conflict(campaign_id) do update set configuration=excluded.configuration,private_notes=excluded.private_notes,elapsed_days=excluded.elapsed_days,revision=legendfolio_campaign_config.revision+1,updated_at=now();
  if p_action='create' and length(trim(coalesce(payload->>'first_session','')))>0 then
   if length(trim(payload->>'first_session'))>160 then raise exception 'First session title is too long' using errcode='22023';end if;
   insert into public.legendfolio_sessions(campaign_id,title,objectives,published) values(c.id,trim(payload->>'first_session'),configuration->>'table_agreement',false) returning id into first_session;
  end if;
 end if;
 result:=public.legendfolio_campaign_foundation_snapshot(c.id);
 insert into public.legendfolio_campaign_config_history(campaign_id,revision,snapshot,actor_id,action) values(c.id,(result->>'revision')::bigint,result,u,action_name);
 insert into public.legendfolio_campaign_events(campaign_id,actor_id,event) values(c.id,u,'Campaign foundation '||action_name);
 insert into public.legendfolio_campaign_config_operations(owner_id,operation_id,request,result) values(u,p_operation,request,result);
 return result;
end $$;
revoke all on function public.legendfolio_campaign_foundation(text,uuid,bigint,text,jsonb,uuid) from public,anon;
grant execute on function public.legendfolio_campaign_foundation(text,uuid,bigint,text,jsonb,uuid) to authenticated;
commit;
