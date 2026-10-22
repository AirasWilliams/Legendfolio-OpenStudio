begin;
create table public.legendfolio_sessions (
 id uuid primary key default gen_random_uuid(), campaign_id uuid not null references public.legendfolio_campaigns(id),
 title text not null check(length(title) between 1 and 160),scheduled_at timestamptz,
 status text not null default 'Planned' check(status in ('Planned','Completed')),
 objectives text not null default '',recap text not null default '',published boolean not null default false,
 archived boolean not null default false,revision bigint not null default 1,
 created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create table public.legendfolio_session_private (
 session_id uuid primary key references public.legendfolio_sessions(id),notes text not null default ''
);
create index legendfolio_sessions_campaign_idx on public.legendfolio_sessions(campaign_id,created_at desc,id desc);
alter table public.legendfolio_sessions enable row level security;
alter table public.legendfolio_session_private enable row level security;
revoke all on public.legendfolio_sessions,public.legendfolio_session_private from public,anon,authenticated;

create function public.legendfolio_session_hub(p_action text,p_campaign_id uuid,p_session_id uuid default null,p_revision bigint default null,p_data jsonb default '{}') returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare u uuid:=auth.uid();c public.legendfolio_campaigns;s public.legendfolio_sessions;old_session public.legendfolio_sessions;is_dm boolean;result jsonb;notes text;cursor_session public.legendfolio_sessions;event_message text;
begin
 if u is null then raise exception 'Sign in first' using errcode='42501';end if;
 select * into c from public.legendfolio_campaigns where id=p_campaign_id and deleted_at is null for share;
 if c.id is null then raise exception 'Campaign unavailable' using errcode='42501';end if;
 is_dm:=c.owner_id=u;
 if not is_dm and not exists(select 1 from public.legendfolio_memberships where campaign_id=c.id and user_id=u and status='approved') then raise exception 'Approved campaign membership required' using errcode='42501';end if;
 if p_action='list' then
  if p_session_id is not null then
   select * into cursor_session from public.legendfolio_sessions where id=p_session_id and campaign_id=c.id and (is_dm or (published and not archived));
   if cursor_session.id is null then raise exception 'Page unavailable' using errcode='42501';end if;
  end if;
  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc,x.id desc),'[]') into result from (
   select id,title,scheduled_at,status,objectives,recap,published,archived,revision,created_at,updated_at from public.legendfolio_sessions
   where campaign_id=c.id and (case when is_dm then archived=coalesce((p_data->>'archived')::boolean,false) else published and not archived end)
   and (cursor_session.id is null or (created_at,id)<(cursor_session.created_at,cursor_session.id))
   order by created_at desc,id desc limit 20
  )x;
  return jsonb_build_object('campaign',c.title,'is_dm',is_dm,'sessions',result,'checked_at',now(),
   'next_session',(select to_jsonb(x) from (select id,title,scheduled_at,status,objectives,published from public.legendfolio_sessions where campaign_id=c.id and not archived and status='Planned' and (is_dm or published) order by scheduled_at asc nulls last,created_at desc,id desc limit 1)x),
   'last_session',(select to_jsonb(x) from (select id,title,scheduled_at,status,recap,published from public.legendfolio_sessions where campaign_id=c.id and not archived and status='Completed' and (is_dm or published) order by scheduled_at desc nulls last,created_at desc,id desc limit 1)x));
 end if;
 if p_action='get' then
  select * into s from public.legendfolio_sessions where id=p_session_id and campaign_id=c.id and (is_dm or (published and not archived));
  if s.id is null then raise exception 'Session unavailable' using errcode='42501';end if;
  result:=to_jsonb(s);if is_dm then result:=result||jsonb_build_object('private_notes',coalesce((select n.notes from public.legendfolio_session_private n where n.session_id=s.id),''));end if;
  return jsonb_build_object('campaign',c.title,'is_dm',is_dm,'session',result);
 end if;
 if p_action not in ('save','archive','restore') then raise exception 'Unknown session action';end if;
 if not is_dm then raise exception 'Only the campaign DM can edit sessions' using errcode='42501';end if;
 if p_session_id is not null then
  select * into s from public.legendfolio_sessions where id=p_session_id and campaign_id=c.id for update;
  if s.id is null then raise exception 'Session unavailable' using errcode='42501';end if;
  if p_revision is null or s.revision<>p_revision then raise exception 'Session changed on another device. Reopen it before saving.' using errcode='40001';end if;
  old_session:=s;
 elsif p_action<>'save' or p_revision is not null then raise exception 'Session unavailable' using errcode='42501';end if;
 if p_action='save' then
  if jsonb_typeof(p_data)<>'object' or jsonb_typeof(p_data->'title') is distinct from 'string' or length(trim(p_data->>'title')) not between 1 and 160 then raise exception 'Enter a session title (1 to 160 characters)';end if;
  if coalesce(length(p_data->>'objectives'),0)>10000 or coalesce(length(p_data->>'recap'),0)>30000 or coalesce(length(p_data->>'private_notes'),0)>30000 then raise exception 'Session notes exceed the allowed length';end if;
  if coalesce(p_data->>'status','Planned') not in ('Planned','Completed') then raise exception 'Choose Planned or Completed';end if;
  if s.id is null then
   insert into public.legendfolio_sessions(campaign_id,title) values(c.id,trim(p_data->>'title')) returning * into s;
  elsif s.archived then raise exception 'Restore the session before editing';end if;
  update public.legendfolio_sessions set title=trim(p_data->>'title'),scheduled_at=nullif(p_data->>'scheduled_at','')::timestamptz,
   status=coalesce(p_data->>'status','Planned'),objectives=coalesce(p_data->>'objectives',''),recap=coalesce(p_data->>'recap',''),published=coalesce((p_data->>'published')::boolean,false),
   revision=case when old_session.id is null then 1 else revision+1 end,updated_at=now() where id=s.id returning * into s;
  insert into public.legendfolio_session_private(session_id,notes) values(s.id,coalesce(p_data->>'private_notes','')) on conflict(session_id) do update set notes=excluded.notes;
 elsif p_action in ('archive','restore') then
  if s.archived=(p_action='archive') then raise exception 'Session is already in that state';end if;
  update public.legendfolio_sessions set archived=(p_action='archive'),revision=revision+1,updated_at=now() where id=s.id returning * into s;
 end if;
 if s.published and not s.archived and (old_session.id is null or not old_session.published or old_session.archived) then event_message:='Session shared: '||s.title;
 elsif old_session.published and not old_session.archived and (not s.published or s.archived) then event_message:='A shared session was withdrawn or archived.';
 elsif s.published and not s.archived and row(s.title,s.scheduled_at,s.status,s.objectives,s.recap) is distinct from row(old_session.title,old_session.scheduled_at,old_session.status,old_session.objectives,old_session.recap) then event_message:='Session updated: '||s.title;
 end if;
 if event_message is not null then insert into public.legendfolio_activity(campaign_id,actor_id,kind,message) values(c.id,u,'session',event_message);end if;
 return jsonb_build_object('id',s.id,'revision',s.revision);
end $$;
revoke all on function public.legendfolio_session_hub(text,uuid,uuid,bigint,jsonb) from public,anon;
grant execute on function public.legendfolio_session_hub(text,uuid,uuid,bigint,jsonb) to authenticated;
commit;
