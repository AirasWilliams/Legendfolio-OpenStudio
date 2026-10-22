begin;
create table public.legendfolio_encounters(
 campaign_id uuid primary key references public.legendfolio_campaigns(id),revision bigint not null default 0,
 scene text not null default 'exploration',title text not null default '',round integer not null default 0,
 current_id text,participants jsonb not null default '[]',history jsonb not null default '[]',updated_at timestamptz not null default now()
);
create table public.legendfolio_encounter_requests(
 actor_id uuid not null,request_id uuid not null,campaign_id uuid not null references public.legendfolio_campaigns(id),payload jsonb not null,
 primary key(actor_id,request_id)
);
alter table public.legendfolio_encounters enable row level security;
alter table public.legendfolio_encounter_requests enable row level security;
revoke all on public.legendfolio_encounters,public.legendfolio_encounter_requests from public,anon,authenticated;
create function public.legendfolio_encounter(p_action text,p_campaign_id uuid,p_payload jsonb default '{}') returns jsonb
language plpgsql security definer set search_path=pg_catalog,public as $$
declare u uuid:=auth.uid();c public.legendfolio_campaigns;s public.legendfolio_encounters;
 req public.legendfolio_encounter_requests;request uuid;people jsonb:='[]';logs jsonb;entry jsonb;item jsonb;pc record;
 modifier integer;initiative integer;die integer;pos integer:=0;nextpos integer;currentpos integer;currentname text;result jsonb;is_dm boolean;
begin
 if u is null then raise exception 'Sign in first' using errcode='42501';end if;
 select * into c from public.legendfolio_campaigns where id=p_campaign_id and deleted_at is null for share;
 if c.id is null then raise exception 'Campaign unavailable' using errcode='42501';end if;
 is_dm:=c.owner_id=u;
 if not is_dm and not exists(select 1 from public.legendfolio_memberships where campaign_id=c.id and user_id=u and status='approved') then raise exception 'Approved membership required' using errcode='42501';end if;
 if p_action is null or p_action not in ('get','prepare','roll','start','next','end','scene') then raise exception 'Unknown encounter action';end if;
 if p_action<>'get' then
  if not is_dm then raise exception 'Only the campaign DM can run encounters' using errcode='42501';end if;
  request:=(p_payload->>'request_id')::uuid;if request is null then raise exception 'Request ID required';end if;
  perform pg_advisory_xact_lock(hashtextextended(u::text||request::text,0));
  select * into req from public.legendfolio_encounter_requests where actor_id=u and request_id=request;
  if req.request_id is not null and (req.campaign_id<>c.id or req.payload<>jsonb_build_object('action',p_action,'data',p_payload)) then raise exception 'Request ID already used';end if;
  insert into public.legendfolio_encounters(campaign_id) values(c.id) on conflict do nothing;
 end if;
 select * into s from public.legendfolio_encounters where campaign_id=c.id for update;
 if p_action<>'get' and req.request_id is null then
  if (p_payload->>'revision')::bigint is distinct from s.revision then raise exception 'Encounter changed. Reload before trying again.' using errcode='40001';end if;
  -- Revoked PCs leave the shared order before any further transition.
  select coalesce(jsonb_agg(value order by ord),'[]') into s.participants from jsonb_array_elements(s.participants) with ordinality x(value,ord)
   where value->>'kind'<>'pc' or exists(select 1 from public.legendfolio_memberships m where m.id::text=value->>'id' and m.campaign_id=c.id and m.status='approved');
  if p_action='prepare' then
   if s.scene='combat' then raise exception 'End combat before preparing another encounter';end if;
   if jsonb_typeof(p_payload->'participants') is distinct from 'array' or jsonb_array_length(p_payload->'participants')>50 then raise exception 'Choose up to 50 participants';end if;
   if length(trim(coalesce(p_payload->>'title','')))>120 then raise exception 'Encounter title is too long';end if;
   for item in select value from jsonb_array_elements(p_payload->'participants') loop
    if coalesce(item->>'modifier','')!~'^-?\d{1,2}$' then raise exception 'Every initiative modifier needs a whole number';end if;
    modifier:=(item->>'modifier')::integer;if modifier not between -30 and 30 then raise exception 'Modifier must be between -30 and 30';end if;
    initiative:=null;
    if coalesce(item->>'initiative','')<>'' then
     if item->>'initiative'!~'^-?\d{1,3}$' then raise exception 'Initiative must be a whole number';end if;
     initiative:=(item->>'initiative')::integer;if initiative not between -99 and 999 then raise exception 'Initiative out of range';end if;
    end if;
    if item->>'kind'='pc' then
     select m.id,coalesce(nullif(m.shared_summary->>'name',''),'Character') as name into pc from public.legendfolio_memberships m where m.id::text=item->>'id' and m.campaign_id=c.id and m.status='approved';
     if pc.id is null then raise exception 'Choose an approved campaign character';end if;
     entry:=jsonb_build_object('id',pc.id,'name',pc.name,'kind','pc');
    elsif item->>'kind' in ('npc','enemy') then
     if length(trim(coalesce(item->>'name',''))) not between 1 and 80 then raise exception 'NPC/enemy name required, up to 80 characters';end if;
     entry:=jsonb_build_object('id','npc-'||pos,'name',trim(item->>'name'),'kind',item->>'kind');
    else raise exception 'Unknown participant kind';end if;
    if exists(select 1 from jsonb_array_elements(people) p where p->>'id'=entry->>'id') then raise exception 'Duplicate participant';end if;
    people:=people||jsonb_build_array(entry||jsonb_build_object('modifier',modifier,'initiative',initiative,'die',null,'position',pos));pos:=pos+1;
   end loop;
   if pos=0 then raise exception 'Add at least one participant';end if;
   s.title:=trim(coalesce(p_payload->>'title','Encounter'));s.participants:=people;s.round:=0;s.current_id:=null;s.history:='[]';
   entry:=jsonb_build_object('text','Encounter prepared','kind','prepare');
  elsif p_action='roll' then
   if s.scene='combat' or jsonb_array_length(s.participants)=0 then raise exception 'Prepare an encounter before rolling';end if;
   for item in select value from jsonb_array_elements(s.participants) loop
    die:=floor(random()*20)::integer+1;
    people:=people||jsonb_build_array(item||jsonb_build_object('die',die,'initiative',die+(item->>'modifier')::integer));
   end loop;
   s.participants:=people;entry:=jsonb_build_object('text','DM rolled initiative for the encounter','kind','initiative','rolls',people);
  elsif p_action='start' then
   if s.scene='combat' or jsonb_array_length(s.participants)=0 or exists(select 1 from jsonb_array_elements(s.participants) p where jsonb_typeof(p->'initiative') is distinct from 'number') then raise exception 'Prepare and set initiative for every participant first';end if;
   select jsonb_agg(value order by (value->>'initiative')::integer desc,(value->>'position')::integer) into s.participants from jsonb_array_elements(s.participants);
   s.scene:='combat';s.round:=1;s.current_id:=s.participants->0->>'id';entry:=jsonb_build_object('text','Combat started','kind','start');
  elsif p_action='next' then
   if s.scene<>'combat' or jsonb_array_length(s.participants)=0 then raise exception 'No active combat';end if;
   select ord::integer-1 into currentpos from jsonb_array_elements(s.participants) with ordinality x(value,ord) where value->>'id'=s.current_id;
   nextpos:=coalesce(currentpos+1,0);if nextpos>=jsonb_array_length(s.participants) then nextpos:=0;s.round:=s.round+1;end if;
   s.current_id:=s.participants->nextpos->>'id';entry:=jsonb_build_object('text','Turn advanced','kind','turn');
  elsif p_action='end' then
   if s.scene<>'combat' then raise exception 'No active combat';end if;
   s.scene:='exploration';s.current_id:=null;entry:=jsonb_build_object('text','Combat ended','kind','end');
  elsif p_action='scene' then
   if s.scene='combat' then raise exception 'End combat before changing scene';end if;
   if p_payload->>'scene' is null or p_payload->>'scene' not in ('exploration','interaction') then raise exception 'Choose exploration or interaction';end if;
   s.scene:=p_payload->>'scene';entry:=jsonb_build_object('text','Scene changed to '||s.scene,'kind','scene');
  end if;
  currentname:=null;select value->>'name' into currentname from jsonb_array_elements(s.participants) where value->>'id'=s.current_id;
  entry:=entry||jsonb_build_object('at',now(),'round',s.round,'current',currentname);
  select coalesce(jsonb_agg(value order by ord),'[]') into logs from jsonb_array_elements(s.history||jsonb_build_array(entry)) with ordinality x(value,ord) where ord>greatest(0,jsonb_array_length(s.history)+1-100);
  update public.legendfolio_encounters set scene=s.scene,title=s.title,round=s.round,current_id=s.current_id,participants=s.participants,history=logs,revision=s.revision+1,updated_at=now() where campaign_id=c.id returning * into s;
  insert into public.legendfolio_encounter_requests values(u,request,c.id,jsonb_build_object('action',p_action,'data',p_payload));
 end if;
 -- Every response is sanitised against current membership, including request retries.
 select coalesce(jsonb_agg(value order by ord),'[]') into people from jsonb_array_elements(coalesce(s.participants,'[]')) with ordinality x(value,ord)
  where value->>'kind'<>'pc' or exists(select 1 from public.legendfolio_memberships m where m.id::text=value->>'id' and m.campaign_id=c.id and m.status='approved');
 result:=jsonb_build_object('campaign',c.title,'is_dm',is_dm,'revision',coalesce(s.revision,0),'scene',coalesce(s.scene,'exploration'),'title',coalesce(s.title,''),'round',coalesce(s.round,0),
  'current_id',case when exists(select 1 from jsonb_array_elements(people) p where p->>'id'=s.current_id) then s.current_id else null end,'participants',people,'history',coalesce(s.history,'[]'),'checked_at',now());
 if is_dm then
  result:=result||jsonb_build_object('setup_members',coalesce((select jsonb_agg(jsonb_build_object('id',m.id,'name',coalesce(nullif(m.shared_summary->>'name',''),'Character'),'modifier',case when coalesce(m.review_snapshot#>>'{fields,Initiative}','')~'^[+-]?\d{1,2}$' then (m.review_snapshot#>>'{fields,Initiative}')::integer else null end) order by m.id) from public.legendfolio_memberships m where m.campaign_id=c.id and m.status='approved'),'[]'::jsonb));
 end if;
 return result;
end $$;
revoke all on function public.legendfolio_encounter(text,uuid,jsonb) from public,anon;
grant execute on function public.legendfolio_encounter(text,uuid,jsonb) to authenticated;
commit;
