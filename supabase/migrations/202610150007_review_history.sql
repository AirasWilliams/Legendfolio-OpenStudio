begin;
create function public.legendfolio_review_history(p_campaign_id uuid,p_before bigint default null,p_review_id bigint default null) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare u uuid:=auth.uid(); result jsonb;
begin
if u is null or not exists(select 1 from public.legendfolio_campaigns where id=p_campaign_id and owner_id=u and deleted_at is null) then raise exception 'Only the campaign DM can view review history' using errcode='42501';end if;
if p_review_id is not null then
 select jsonb_build_object('id',r.id,'decision',r.decision,'at',r.created_at,'previous',r.previous_snapshot,'next',r.next_snapshot) into result from public.legendfolio_character_reviews r where r.campaign_id=p_campaign_id and r.id=p_review_id;
 if result is null then raise exception 'Review unavailable' using errcode='42501';end if;
 return result;
end if;
return coalesce((select jsonb_agg(to_jsonb(x) order by x.id desc) from (select r.id,r.membership_id,r.decision,r.created_at,coalesce(nullif(p.display_name,''),'Account') as actor,coalesce(r.next_snapshot#>>'{fields,CharacterName}',r.previous_snapshot#>>'{fields,CharacterName}','Character') as character from public.legendfolio_character_reviews r left join public.legendfolio_profiles p on p.id=r.actor_id where r.campaign_id=p_campaign_id and (p_before is null or r.id<p_before) order by r.id desc limit 20)x),'[]');
end $$;
revoke all on function public.legendfolio_review_history(uuid,bigint,bigint) from public,anon;
grant execute on function public.legendfolio_review_history(uuid,bigint,bigint) to authenticated;
commit;
