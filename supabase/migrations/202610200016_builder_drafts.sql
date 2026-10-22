-- Private, revisioned builder workspace. Campaign approval still uses the existing exact-version workflow.
begin;
create table public.legendfolio_builder_drafts(
 id uuid primary key default gen_random_uuid(),owner_id uuid not null references auth.users(id) on delete cascade,
 title text not null check(length(title) between 1 and 100),edition text not null check(edition in ('2014','2024')),
 campaign_id uuid references public.legendfolio_campaigns(id) on delete set null,
 draft_data jsonb not null check(jsonb_typeof(draft_data)='object' and octet_length(draft_data::text)<=131072),
 validation jsonb not null,revision bigint not null default 1,archived boolean not null default false,
 created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create table public.legendfolio_builder_history(
 draft_id uuid not null references public.legendfolio_builder_drafts(id) on delete cascade,revision bigint not null,
 owner_id uuid not null references auth.users(id) on delete cascade,snapshot jsonb not null,created_at timestamptz not null default now(),primary key(draft_id,revision)
);
create table public.legendfolio_builder_operations(
 owner_id uuid not null references auth.users(id) on delete cascade,operation_id uuid not null,request jsonb not null,result jsonb not null,
 created_at timestamptz not null default now(),primary key(owner_id,operation_id)
);
create table public.legendfolio_builder_rules(
 campaign_id uuid primary key references public.legendfolio_campaigns(id) on delete cascade,
 editions jsonb not null default '["2014","2024"]',allow_custom boolean not null default true,revision bigint not null default 1,updated_at timestamptz not null default now()
);
create index lf_builder_owner_updated on public.legendfolio_builder_drafts(owner_id,updated_at desc);
alter table public.legendfolio_builder_drafts enable row level security;
alter table public.legendfolio_builder_drafts force row level security;
alter table public.legendfolio_builder_history enable row level security;
alter table public.legendfolio_builder_history force row level security;
alter table public.legendfolio_builder_operations enable row level security;
alter table public.legendfolio_builder_operations force row level security;
alter table public.legendfolio_builder_rules enable row level security;
alter table public.legendfolio_builder_rules force row level security;
revoke all on public.legendfolio_builder_drafts,public.legendfolio_builder_history,public.legendfolio_builder_operations,public.legendfolio_builder_rules from anon,authenticated;
grant select on public.legendfolio_builder_drafts,public.legendfolio_builder_history to authenticated;
create policy lf_builder_own_read on public.legendfolio_builder_drafts for select to authenticated using(owner_id=(select auth.uid()));
create policy lf_builder_own_history on public.legendfolio_builder_history for select to authenticated using(owner_id=(select auth.uid()));

create function public.legendfolio_validate_builder(p_draft jsonb,p_edition text) returns jsonb
language plpgsql immutable set search_path=pg_catalog,public as $$
declare errors jsonb:='[]';considerations jsonb:='[]';scores jsonb:=p_draft#>'{abilities,scores}';method text:=p_draft#>>'{abilities,method}';k text;v jsonb;total int:=0;n int;assigned int[];rolled int[];
begin
 if p_edition not in ('2014','2024') or p_edition is null then errors:=errors||jsonb_build_array('Choose a supported rules edition.');end if;
 if jsonb_typeof(p_draft) is distinct from 'object' or octet_length(p_draft::text)>131072 then return jsonb_build_object('errors',jsonb_build_array('Invalid builder draft.'),'considerations','[]'::jsonb,'mechanically_complete',false);end if;
 if length(trim(coalesce(p_draft->>'name',''))) not between 1 and 100 then errors:=errors||jsonb_build_array('Character name must contain 1–100 characters.');end if;
 if length(coalesce(p_draft->>'concept',''))>12000 or length(coalesce(p_draft->>'ancestry',''))>200 or length(coalesce(p_draft->>'className',''))>200 or length(coalesce(p_draft->>'background',''))>300 then errors:=errors||jsonb_build_array('A concept field exceeds its allowed length.');end if;
 if p_draft ?| array['owner_id','characterApproval','approved','approval_status'] then errors:=errors||jsonb_build_array('Draft data cannot assign ownership or campaign approval.');end if;
 if p_draft ? 'edition' and p_draft->>'edition' is distinct from p_edition then errors:=errors||jsonb_build_array('The draft and rules edition do not match.');end if;
 if p_draft ? 'customProposals' and jsonb_typeof(p_draft->'customProposals') is distinct from 'array' then errors:=errors||jsonb_build_array('Custom proposals must be an array.');end if;
 if coalesce(jsonb_typeof(p_draft->'customProposals')='array',false) and jsonb_array_length(p_draft->'customProposals')>0 then considerations:=considerations||jsonb_build_array('Custom mechanics require an explicit DM review.');end if;
 if scores is not null then
  if jsonb_typeof(scores) is distinct from 'object' then errors:=errors||jsonb_build_array('Ability scores must be an object.');
  else
   if (select count(*) from jsonb_object_keys(scores))<>6 or not(scores ?& array['STR','DEX','CON','INT','WIS','CHA']) then errors:=errors||jsonb_build_array('Assign all six ability scores once.');end if;
   for k,v in select * from jsonb_each(scores) loop
    if k<>all(array['STR','DEX','CON','INT','WIS','CHA']) or jsonb_typeof(v)<>'number' or v::text !~ '^\d+$' then errors:=errors||jsonb_build_array('Ability scores must be whole numbers with valid ability names.');continue;end if;
    n:=(v::text)::int;if n<3 or n>20 then errors:=errors||jsonb_build_array('Base ability scores must be between 3 and 20.');end if;
    if method='point-buy' then
     if n<8 or n>15 then errors:=errors||jsonb_build_array('Point-buy scores must be between 8 and 15.');else total:=total+case when n<=13 then n-8 when n=14 then 7 else 9 end;end if;
    end if;
   end loop;
   if method not in ('standard-array','point-buy','rolled','custom') or method is null then errors:=errors||jsonb_build_array('Choose an ability allocation method.');end if;
   if jsonb_array_length(errors)=0 then
    select array_agg((value::text)::int order by (value::text)::int) into assigned from jsonb_each(scores);
    if method='standard-array' and assigned<>array[8,10,12,13,14,15] then errors:=errors||jsonb_build_array('The standard array must use 15, 14, 13, 12, 10 and 8 exactly once.');end if;
    if method='rolled' then
     if jsonb_typeof(p_draft#>'{abilities,rolls}') is distinct from 'array' then errors:=errors||jsonb_build_array('Record the original six rolls.');
     elsif exists(select 1 from jsonb_array_elements(p_draft#>'{abilities,rolls}') x where jsonb_typeof(x)<>'number' or x::text !~ '^\d+$') then errors:=errors||jsonb_build_array('Original rolls must be whole numbers.');
     else select array_agg((x::text)::int order by (x::text)::int) into rolled from jsonb_array_elements(p_draft#>'{abilities,rolls}') x;if rolled is distinct from assigned then errors:=errors||jsonb_build_array('Assigned scores do not match the original rolls.');end if;end if;
    end if;
   end if;
   if method='point-buy' and total>27 then errors:=errors||jsonb_build_array('Point buy exceeds the 27-point budget.');end if;
   if method in ('rolled','custom') then considerations:=considerations||jsonb_build_array('Confirm the ability generation method with the DM.');end if;
  end if;
 else considerations:=considerations||jsonb_build_array('Ability scores are not allocated.');end if;
 if p_draft ? 'proficiencies' then
  if jsonb_typeof(p_draft->'proficiencies') is distinct from 'array' then errors:=errors||jsonb_build_array('Proficiencies must be an array.');
  elsif (select count(*)<>count(distinct lower(trim(value))) from jsonb_array_elements_text(p_draft->'proficiencies')) then errors:=errors||jsonb_build_array('Duplicate proficiencies require a replacement choice.');end if;
 end if;
 considerations:=considerations||jsonb_build_array('Class progression, species traits, background benefits, equipment and spell choices still require rules-catalog validation.');
 return jsonb_build_object('edition',p_edition,'validation_scope','draft-integrity-and-ability-allocation','errors',errors,'considerations',considerations,'mechanically_complete',false,'campaign_approved',false);
end $$;
revoke all on function public.legendfolio_validate_builder(jsonb,text) from public,anon,authenticated;

create function public.legendfolio_builder_policy(p_campaign uuid,p_rules jsonb default null,p_expected_revision bigint default null) returns jsonb
language plpgsql security definer set search_path=pg_catalog,public as $$
declare u uuid:=auth.uid();c public.legendfolio_campaigns;r public.legendfolio_builder_rules;
begin
 if u is null then raise exception 'Sign in first' using errcode='42501';end if;
 select * into c from public.legendfolio_campaigns where id=p_campaign and deleted_at is null;
 if c.id is null or not(c.owner_id=u or exists(select 1 from public.legendfolio_memberships where campaign_id=c.id and user_id=u and status in ('approved','pending'))) then raise exception 'Campaign not available' using errcode='42501';end if;
 if p_rules is not null then
  if c.owner_id<>u then raise exception 'Only the campaign owner can change builder rules' using errcode='42501';end if;
  perform pg_advisory_xact_lock(hashtextextended(c.id::text,0));
  if jsonb_typeof(p_rules->'editions') is distinct from 'array' or jsonb_array_length(p_rules->'editions') not between 1 and 2 or exists(select 1 from jsonb_array_elements_text(p_rules->'editions') x where x not in ('2014','2024')) or jsonb_typeof(p_rules->'allow_custom') is distinct from 'boolean' then raise exception 'Invalid builder policy' using errcode='22023';end if;
  select * into r from public.legendfolio_builder_rules where campaign_id=c.id for update;
  if coalesce(r.revision,0) is distinct from p_expected_revision then raise exception 'Builder rules changed. Reload before replacing.' using errcode='40001';end if;
  insert into public.legendfolio_builder_rules(campaign_id,editions,allow_custom,revision) values(c.id,p_rules->'editions',(p_rules->>'allow_custom')::boolean,coalesce(r.revision,0)+1)
   on conflict(campaign_id) do update set editions=excluded.editions,allow_custom=excluded.allow_custom,revision=excluded.revision,updated_at=now();
 end if;
 select * into r from public.legendfolio_builder_rules where campaign_id=c.id;
 return case when r.campaign_id is null then jsonb_build_object('campaign_id',c.id,'editions',jsonb_build_array('2014','2024'),'allow_custom',true,'revision',0) else to_jsonb(r) end;
end $$;

create function public.legendfolio_builder_draft(p_action text,p_id uuid default null,p_expected_revision bigint default null,p_edition text default null,p_campaign uuid default null,p_draft jsonb default null,p_operation uuid default null) returns jsonb
language plpgsql security definer set search_path=pg_catalog,public as $$
declare u uuid:=auth.uid();d public.legendfolio_builder_drafts;request jsonb;previous public.legendfolio_builder_operations;result jsonb;checked jsonb;policy jsonb;
begin
 if u is null then raise exception 'Sign in first' using errcode='42501';end if;
 if p_action='list' then return coalesce((select jsonb_agg(to_jsonb(x)) from(select id,title,edition,campaign_id,revision,archived,updated_at from public.legendfolio_builder_drafts where owner_id=u order by updated_at desc)x),'[]');end if;
 if p_action in ('get','history') then
  select * into d from public.legendfolio_builder_drafts where id=p_id and owner_id=u;
  if d.id is null then raise exception 'Builder draft not available' using errcode='42501';end if;
  if p_action='get' then return to_jsonb(d);end if;
  return coalesce((select jsonb_agg(to_jsonb(x)) from(select revision,snapshot,created_at from public.legendfolio_builder_history where draft_id=d.id and owner_id=u order by revision desc limit 50)x),'[]');
 end if;
 if p_action not in ('save','archive','restore') or p_operation is null then raise exception 'Choose an operation and a unique request id' using errcode='22023';end if;
 request:=jsonb_build_object('action',p_action,'id',p_id,'revision',p_expected_revision,'edition',p_edition,'campaign',p_campaign,'draft',p_draft);
 perform pg_advisory_xact_lock(hashtextextended(u::text||p_operation::text,0));
 select * into previous from public.legendfolio_builder_operations where owner_id=u and operation_id=p_operation;
 if previous.operation_id is not null then if previous.request<>request then raise exception 'Request id was reused with different data' using errcode='22023';end if;return previous.result;end if;
 if p_id is not null then
  select * into d from public.legendfolio_builder_drafts where id=p_id and owner_id=u for update;
  if d.id is null then raise exception 'Builder draft not available' using errcode='42501';end if;
  if d.revision is distinct from p_expected_revision then raise exception 'Builder draft changed on another device. Reload or save a separate copy.' using errcode='40001';end if;
 elsif p_action<>'save' or p_expected_revision is not null then raise exception 'Choose an existing draft' using errcode='22023';end if;
 if p_action='save' then
  checked:=public.legendfolio_validate_builder(p_draft,p_edition);
  if jsonb_array_length(checked->'errors')>0 then raise exception '%',(checked->'errors')::text using errcode='22023';end if;
  if p_campaign is not null then
   policy:=public.legendfolio_builder_policy(p_campaign);
   if not(policy->'editions' ? p_edition) then raise exception 'This edition is not allowed by the campaign' using errcode='22023';end if;
   if not(policy->>'allow_custom')::boolean and (coalesce(jsonb_array_length(p_draft->'customProposals'),0)>0 or lower(coalesce(p_draft->>'className','')) like '%custom%') then raise exception 'The campaign does not allow custom mechanical proposals' using errcode='22023';end if;
   checked:=checked||jsonb_build_object('campaign_policy_revision',policy->'revision');
  end if;
  if d.id is null then insert into public.legendfolio_builder_drafts(owner_id,title,edition,campaign_id,draft_data,validation) values(u,trim(p_draft->>'name'),p_edition,p_campaign,p_draft,checked) returning * into d;
  else update public.legendfolio_builder_drafts set title=trim(p_draft->>'name'),edition=p_edition,campaign_id=p_campaign,draft_data=p_draft,validation=checked,revision=revision+1,updated_at=now() where id=d.id returning * into d;end if;
 else update public.legendfolio_builder_drafts set archived=p_action='archive',revision=revision+1,updated_at=now() where id=d.id returning * into d;end if;
 result:=to_jsonb(d);
 insert into public.legendfolio_builder_history(draft_id,revision,owner_id,snapshot) values(d.id,d.revision,u,result);
 insert into public.legendfolio_builder_operations(owner_id,operation_id,request,result) values(u,p_operation,request,result);
 return result;
end $$;
revoke all on function public.legendfolio_builder_draft(text,uuid,bigint,text,uuid,jsonb,uuid),public.legendfolio_builder_policy(uuid,jsonb,bigint) from public,anon;
grant execute on function public.legendfolio_builder_draft(text,uuid,bigint,text,uuid,jsonb,uuid),public.legendfolio_builder_policy(uuid,jsonb,bigint) to authenticated;
commit;
