begin;
create table public.legendfolio_campaign_people(id uuid primary key default gen_random_uuid(),campaign_id uuid not null references public.legendfolio_campaigns(id) on delete cascade,source_id text not null,kind text not null check(kind in ('npc','dm_character')),name text not null check(length(name) between 1 and 160),role text not null default '',description text not null default '',portrait text,visible boolean not null default false,unique(campaign_id,source_id));
alter table public.legendfolio_campaign_people enable row level security;
revoke all on public.legendfolio_campaign_people from anon,authenticated;
create function public.legendfolio_campaign_people_action(p_action text,p_payload jsonb default '{}') returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare u uuid:=auth.uid();c public.legendfolio_campaigns;result jsonb;
begin
if u is null then raise exception 'Sign in first' using errcode='42501';end if;
select * into c from public.legendfolio_campaigns where id=(p_payload->>'campaign_id')::uuid;
if c.id is null then raise exception 'Campaign unavailable' using errcode='42501';end if;
if p_action='list' then
 if c.owner_id<>u and not exists(select 1 from public.legendfolio_memberships where campaign_id=c.id and user_id=u and status='approved') then raise exception 'Access denied' using errcode='42501';end if;
 return jsonb_build_object('dm',jsonb_build_object('name',coalesce(nullif((select display_name from public.legendfolio_profiles where id=c.owner_id),''),'Dungeon Master'),'kind','dm'),'people',coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'source_id',p.source_id,'kind',p.kind,'name',p.name,'role',p.role,'description',p.description,'portrait',p.portrait,'visible',p.visible) order by p.name) from public.legendfolio_campaign_people p where p.campaign_id=c.id and (p.visible or c.owner_id=u)),'[]'));
end if;
if c.owner_id<>u then raise exception 'Only the campaign DM can publish characters' using errcode='42501';end if;
if p_action='publish' then
 if p_payload->>'kind' not in ('npc','dm_character') or p_payload->>'kind' is null then raise exception 'Invalid character type';end if;
 if length(trim(coalesce(p_payload->>'source_id','')))=0 then raise exception 'Source required';end if;
 if p_payload->>'portrait' is not null and (length(p_payload->>'portrait')>3000000 or p_payload->>'portrait' !~ '^data:image/(png|jpeg|webp);base64,') then raise exception 'Invalid portrait';end if;
 insert into public.legendfolio_campaign_people(campaign_id,source_id,kind,name,role,description,portrait,visible) values(c.id,left(p_payload->>'source_id',200),p_payload->>'kind',left(trim(p_payload->>'name'),160),left(coalesce(p_payload->>'role',''),160),left(coalesce(p_payload->>'description',''),4000),p_payload->>'portrait',true) on conflict(campaign_id,source_id) do update set kind=excluded.kind,name=excluded.name,role=excluded.role,description=excluded.description,portrait=excluded.portrait,visible=true;
elsif p_action='hide' then update public.legendfolio_campaign_people set visible=false where campaign_id=c.id and id=(p_payload->>'id')::uuid;
else raise exception 'Unknown action';end if;
insert into public.legendfolio_campaign_events(campaign_id,actor_id,event) values(c.id,u,'Campaign directory '||p_action);return jsonb_build_object('ok',true);
end $$;
revoke all on function public.legendfolio_campaign_people_action(text,jsonb) from public,anon;
grant execute on function public.legendfolio_campaign_people_action(text,jsonb) to authenticated;
commit;
