begin;
alter table public.legendfolio_memberships add column review_snapshot jsonb, add column submitted_revision bigint, add column proposed_snapshot jsonb, add column proposed_revision bigint, add column change_state text not null default 'none' check(change_state in ('none','pending','approved','rejected'));
create table public.legendfolio_character_reviews(id bigint generated always as identity primary key,campaign_id uuid not null references public.legendfolio_campaigns(id),membership_id uuid not null references public.legendfolio_memberships(id),actor_id uuid not null,decision text not null,previous_snapshot jsonb,next_snapshot jsonb,created_at timestamptz not null default now());
alter table public.legendfolio_character_reviews enable row level security;
revoke all on public.legendfolio_character_reviews from anon,authenticated;
-- Backfill only previously authorised character links for DM review.
update public.legendfolio_memberships m set review_snapshot=c.character_data,submitted_revision=c.revision from public.legendfolio_characters c where c.id=m.character_id and c.owner_id=m.user_id;
create or replace function public.legendfolio_campaign_action(p_action text,p_payload jsonb default '{}') returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
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
 insert into public.legendfolio_memberships(campaign_id,user_id,character_id,party_role,review_snapshot,submitted_revision,shared_summary) values(c.id,u,ch.id,left(coalesce(p_payload->>'party_role',''),80),ch.character_data,ch.revision,jsonb_build_object('name',ch.character_name,'player',coalesce((select display_name from public.legendfolio_profiles where id=u),''),'class',ch.character_data#>>'{fields,ClassLevel}','level',coalesce(ch.character_data#>>'{fields,Level}',ch.character_data#>>'{companion,level}'),'portrait',ch.character_data#>>'{art,portrait}')) on conflict(campaign_id,user_id,character_id) do nothing returning * into m;
 if m.id is null then return jsonb_build_object('error','This character already has a request.');end if;
 update public.legendfolio_invites set uses=uses+1 where id=i.id;
 insert into public.legendfolio_campaign_events(campaign_id,actor_id,event) values(c.id,u,'Character requested membership');return to_jsonb(m);
end if;
select * into c from public.legendfolio_campaigns where id=(p_payload->>'campaign_id')::uuid;
if c.id is null then raise exception 'Campaign unavailable' using errcode='42501';end if;
if p_action='details' then
 if c.owner_id<>u and not exists(select 1 from public.legendfolio_memberships where campaign_id=c.id and user_id=u and status='approved') then raise exception 'Access denied' using errcode='42501';end if;
 return to_jsonb(c);
end if;
if p_action='submit_change' then
 select * into m from public.legendfolio_memberships where id=(p_payload->>'membership_id')::uuid and campaign_id=c.id and user_id=u and status='approved' for update;
 if m.id is null then raise exception 'Approved membership required' using errcode='42501';end if;
 if m.change_state='pending' then raise exception 'A change is already awaiting review';end if;
 select * into ch from public.legendfolio_characters where id=m.character_id and owner_id=u;
 if ch.id is null then raise exception 'Character unavailable';end if;
 update public.legendfolio_memberships set proposed_snapshot=ch.character_data,proposed_revision=ch.revision,change_state='pending' where id=m.id;
 insert into public.legendfolio_character_reviews(campaign_id,membership_id,actor_id,decision,previous_snapshot,next_snapshot) values(c.id,m.id,u,'submitted',m.review_snapshot,ch.character_data);
 return jsonb_build_object('ok',true);
end if;
if p_action='leave' then
 update public.legendfolio_memberships set status='rejected' where campaign_id=c.id and user_id=u;
 insert into public.legendfolio_campaign_events(campaign_id,actor_id,event) values(c.id,u,'Player left campaign');return jsonb_build_object('ok',true);
end if;
if p_action='roster' then
 if c.owner_id<>u and not exists(select 1 from public.legendfolio_memberships where campaign_id=c.id and user_id=u and status='approved') then raise exception 'Access denied' using errcode='42501';end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',mm.id,'status',mm.status,'party_role',mm.party_role,'change_state',mm.change_state,'is_own',mm.user_id=u,'summary',case when c.owner_id=u or mm.user_id=u or coalesce(c.settings->>'roster_visibility','party')='party' then mm.shared_summary else jsonb_build_object('name',mm.shared_summary->>'name') end)) from public.legendfolio_memberships mm where mm.campaign_id=c.id and (c.owner_id=u or mm.status='approved')),'[]');end if;
if c.owner_id<>u then raise exception 'Only the campaign DM can do this' using errcode='42501';end if;
if p_action='settings' then
 if length(trim(coalesce(p_payload->>'title','')))=0 then raise exception 'Campaign title required';end if;
 if p_payload->>'roster_visibility' not in ('party','names') then raise exception 'Invalid roster visibility';end if;
 update public.legendfolio_campaigns set title=left(trim(p_payload->>'title'),160),description=left(coalesce(p_payload->>'description',''),10000),game_system=left(coalesce(p_payload->>'game_system','dnd5e'),80),settings=settings||jsonb_build_object('roster_visibility',p_payload->>'roster_visibility') where id=c.id;
elsif p_action='character_review' then
 select * into m from public.legendfolio_memberships where id=(p_payload->>'membership_id')::uuid and campaign_id=c.id;
 if m.id is null then raise exception 'Request unavailable';end if;
 return jsonb_build_object('id',m.id,'status',m.status,'character',m.review_snapshot,'revision',m.submitted_revision,'proposed',m.proposed_snapshot,'change_state',m.change_state,'proposed_revision',m.proposed_revision);
elsif p_action='review_change' then
 if p_payload->>'decision' not in ('approved','rejected') then raise exception 'Invalid decision';end if;
 select * into m from public.legendfolio_memberships where id=(p_payload->>'membership_id')::uuid and campaign_id=c.id and status='approved' for update;
 if m.id is null or m.change_state<>'pending' or m.proposed_revision is distinct from (p_payload->>'expected_revision')::bigint then raise exception 'Review changed. Reload before deciding' using errcode='40001';end if;
 insert into public.legendfolio_character_reviews(campaign_id,membership_id,actor_id,decision,previous_snapshot,next_snapshot) values(c.id,m.id,u,p_payload->>'decision',m.review_snapshot,m.proposed_snapshot);
 update public.legendfolio_memberships set shared_summary=case when p_payload->>'decision'='approved' then shared_summary||jsonb_build_object('name',proposed_snapshot#>>'{fields,CharacterName}','class',proposed_snapshot#>>'{fields,ClassLevel}','level',coalesce(proposed_snapshot#>>'{fields,Level}',proposed_snapshot#>>'{companion,level}'),'portrait',proposed_snapshot#>>'{art,portrait}') else shared_summary end,review_snapshot=case when p_payload->>'decision'='approved' then proposed_snapshot else review_snapshot end,submitted_revision=case when p_payload->>'decision'='approved' then proposed_revision else submitted_revision end,change_state=p_payload->>'decision',proposed_snapshot=null,proposed_revision=null where id=m.id;
elsif p_action='member_role' then
 update public.legendfolio_memberships set party_role=left(coalesce(p_payload->>'party_role',''),80) where id=(p_payload->>'membership_id')::uuid and campaign_id=c.id;
elsif p_action='invite' then
 insert into public.legendfolio_invites(campaign_id,code,expires_at,usage_limit) values(c.id,upper(replace(gen_random_uuid()::text,'-','')),now()+make_interval(hours=>greatest(1,least(720,coalesce((p_payload->>'hours')::int,168)))),nullif(p_payload->>'usage_limit','')::int) returning * into i;return to_jsonb(i);
elsif p_action='invites' then return coalesce((select jsonb_agg(to_jsonb(ii)) from public.legendfolio_invites ii where ii.campaign_id=c.id),'[]');
elsif p_action='revoke' then update public.legendfolio_invites set revoked=true where id=(p_payload->>'invite_id')::uuid and campaign_id=c.id;
elsif p_action='review' then
 if p_payload->>'status' not in ('approved','rejected') then raise exception 'Invalid decision';end if;
 update public.legendfolio_memberships set status=p_payload->>'status' where id=(p_payload->>'membership_id')::uuid and campaign_id=c.id;
else raise exception 'Unknown campaign action';end if;
insert into public.legendfolio_campaign_events(campaign_id,actor_id,event) values(c.id,u,p_action);return jsonb_build_object('ok',true);
end $$;
commit;
