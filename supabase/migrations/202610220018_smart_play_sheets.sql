-- SMART PLAY campaign PDF templates. Profiles reuse the existing private profile table.
begin;
create table public.legendfolio_sheet_templates (
 campaign_id uuid not null references public.legendfolio_campaigns(id) on delete cascade,
 revision bigint not null check(revision>0),
 operation_id uuid not null,
 request_hash text not null,
 template jsonb not null,
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now(),
 primary key(campaign_id,revision), unique(campaign_id,operation_id)
);
alter table public.legendfolio_sheet_templates enable row level security;
alter table public.legendfolio_sheet_templates force row level security;
revoke all on public.legendfolio_sheet_templates from public,anon,authenticated;
create function public.legendfolio_sheet_template(p_campaign_id uuid,p_action text,p_expected_revision bigint default null,p_template jsonb default '{}'::jsonb,p_operation_id uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); c public.legendfolio_campaigns; row public.legendfolio_sheet_templates; current_revision bigint; request text; k text; v jsonb;
begin
 if u is null then raise exception 'Sign in to access campaign sheets' using errcode='28000';end if;
 select * into c from public.legendfolio_campaigns where id=p_campaign_id and deleted_at is null for update;
 if not found then raise exception 'Campaign unavailable' using errcode='42501';end if;
 if c.owner_id<>u and not exists(select 1 from public.legendfolio_memberships where campaign_id=c.id and user_id=u and status='approved') then raise exception 'Campaign unavailable' using errcode='42501';end if;
 if p_action='get' then
  select * into row from public.legendfolio_sheet_templates where campaign_id=c.id order by revision desc limit 1;
  if not found then return null;end if;
  return row.template||jsonb_build_object('revision',row.revision);
 end if;
 if p_action<>'save' or c.owner_id<>u then raise exception 'Only the campaign owner may publish a sheet' using errcode='42501';end if;
 if p_operation_id is null then raise exception 'Operation ID required' using errcode='22023';end if;
 if not coalesce(jsonb_typeof(p_template)='object' and jsonb_typeof(p_template->'name')='string' and length(trim(p_template->>'name')) between 1 and 100 and jsonb_typeof(p_template->'pdf')='string' and length(p_template->>'pdf') between 12 and 2800000 and (p_template->>'pdf')~'^JVBERi0[A-Za-z0-9+/=\r\n]+$' and jsonb_typeof(p_template->'mapping')='object',false) then raise exception 'Invalid campaign sheet template' using errcode='22023';end if;
 if (select count(*) from jsonb_object_keys(p_template->'mapping'))>650 or octet_length(p_template::text)>3200000 then raise exception 'Campaign sheet is too large' using errcode='22023';end if;
 for k,v in select * from jsonb_each(p_template->'mapping') loop
  if length(k)>240 or jsonb_typeof(v)<>'string' or length(v#>>'{}')>240 then raise exception 'Invalid sheet field mapping' using errcode='22023';end if;
 end loop;
 p_template:=jsonb_build_object('name',trim(p_template->>'name'),'pdf',p_template->>'pdf','mapping',p_template->'mapping');request:=md5(p_template::text);
 select * into row from public.legendfolio_sheet_templates where campaign_id=c.id and operation_id=p_operation_id;
 if found then
  if row.request_hash<>request then raise exception 'Operation ID reused for different sheet' using errcode='22023';end if;
  return row.template||jsonb_build_object('revision',row.revision);
 end if;
 select max(revision) into current_revision from public.legendfolio_sheet_templates where campaign_id=c.id;
 if current_revision is distinct from p_expected_revision then raise exception 'Campaign sheet changed. Reopen it before saving.' using errcode='40001';end if;
 insert into public.legendfolio_sheet_templates(campaign_id,revision,operation_id,request_hash,template,created_by) values(c.id,coalesce(current_revision,0)+1,p_operation_id,request,p_template,u) returning * into row;
 return row.template||jsonb_build_object('revision',row.revision);
end $$;
revoke all on function public.legendfolio_sheet_template(uuid,text,bigint,jsonb,uuid) from public,anon;
grant execute on function public.legendfolio_sheet_template(uuid,text,bigint,jsonb,uuid) to authenticated;
commit;
