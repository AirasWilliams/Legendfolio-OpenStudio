begin;
create function public.legendfolio_own_approved_sheet(p_campaign_id uuid,p_membership_id uuid) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare result jsonb;
begin
if auth.uid() is null then raise exception 'Sign in first' using errcode='42501';end if;
select jsonb_build_object('character',m.review_snapshot,'revision',m.submitted_revision,'change_state',m.change_state,'campaign',c.title) into result from public.legendfolio_memberships m join public.legendfolio_campaigns c on c.id=m.campaign_id where m.id=p_membership_id and m.campaign_id=p_campaign_id and m.user_id=auth.uid() and m.status='approved' and c.deleted_at is null;
if result is null then raise exception 'Your approved character is unavailable' using errcode='42501';end if;
return result;
end $$;
revoke all on function public.legendfolio_own_approved_sheet(uuid,uuid) from public,anon;
grant execute on function public.legendfolio_own_approved_sheet(uuid,uuid) to authenticated;
commit;
