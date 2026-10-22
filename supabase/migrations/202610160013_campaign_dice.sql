begin;
create table public.legendfolio_dice_rolls(
 id bigint generated always as identity primary key,campaign_id uuid not null references public.legendfolio_campaigns(id),
 user_id uuid not null references auth.users(id),request_id uuid not null,request_data jsonb not null,
 character_name text not null,player_name text not null,result jsonb not null,created_at timestamptz not null default now(),unique(user_id,request_id)
);
create index legendfolio_dice_campaign_idx on public.legendfolio_dice_rolls(campaign_id,id desc);
create index legendfolio_dice_user_time_idx on public.legendfolio_dice_rolls(user_id,created_at desc);
create table public.legendfolio_dice_reads(user_id uuid not null references auth.users(id),campaign_id uuid not null references public.legendfolio_campaigns(id),through_id bigint not null default 0,primary key(user_id,campaign_id));
alter table public.legendfolio_dice_rolls enable row level security;alter table public.legendfolio_dice_reads enable row level security;
revoke all on public.legendfolio_dice_rolls,public.legendfolio_dice_reads from public,anon,authenticated;
create function public.legendfolio_dice(p_action text,p_campaign_id uuid default null,p_payload jsonb default '{}') returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare u uuid:=auth.uid();c public.legendfolio_campaigns;m public.legendfolio_memberships;r public.legendfolio_dice_rolls;request uuid;piece jsonb;groups jsonb:='[]';dice jsonb;rolls jsonb;sides int;n int;modifier int;mode text;label text;formula text:='';subtotal int;total int:=0;physical int:=0;selected int:=0;value int;seen int[]:='{}';character_name text;player_name text;response jsonb;latest bigint;before_id bigint;
begin
 if u is null then raise exception 'Sign in first' using errcode='42501';end if;
 if p_action='summary' then return jsonb_build_object('unread',(select count(*) from public.legendfolio_dice_rolls d join public.legendfolio_campaigns ca on ca.id=d.campaign_id left join public.legendfolio_dice_reads rd on rd.campaign_id=ca.id and rd.user_id=u where ca.owner_id=u and ca.deleted_at is null and d.user_id<>u and d.id>coalesce(rd.through_id,0)),
 'latest',coalesce((select jsonb_agg(to_jsonb(x)) from (select d.character_name,ca.title as campaign,d.result->>'formula' as formula,d.result->'total' as total,d.result->'dice_count' as dice_count from public.legendfolio_dice_rolls d join public.legendfolio_campaigns ca on ca.id=d.campaign_id left join public.legendfolio_dice_reads rd on rd.campaign_id=ca.id and rd.user_id=u where ca.owner_id=u and ca.deleted_at is null and d.user_id<>u and d.id>coalesce(rd.through_id,0) order by d.id desc limit 2)x),'[]'));end if;
 if p_action in ('list','read') then
  if p_campaign_id is not null and not exists(select 1 from public.legendfolio_campaigns where id=p_campaign_id and owner_id=u and deleted_at is null) then raise exception 'Only the campaign DM can view this roll log' using errcode='42501';end if;
  if p_action='read' then
   if p_campaign_id is null then raise exception 'Choose a campaign';end if;
   select max(d.id) into latest from public.legendfolio_dice_rolls d join public.legendfolio_campaigns ca on ca.id=d.campaign_id where ca.id=p_campaign_id and ca.owner_id=u and ca.deleted_at is null and d.id<=(p_payload->>'through')::bigint;
   if latest is null then raise exception 'Roll unavailable' using errcode='42501';end if;
   insert into public.legendfolio_dice_reads values(u,p_campaign_id,latest) on conflict(user_id,campaign_id) do update set through_id=greatest(legendfolio_dice_reads.through_id,excluded.through_id);
  end if;
  before_id:=nullif(p_payload->>'before','')::bigint;
  select coalesce(jsonb_agg(to_jsonb(x) order by x.id desc),'[]') into response from (
   select d.id,d.campaign_id,ca.title as campaign,d.character_name,d.player_name,d.result,d.created_at,d.user_id<>u and d.id>coalesce(rd.through_id,0) as unread
   from public.legendfolio_dice_rolls d join public.legendfolio_campaigns ca on ca.id=d.campaign_id left join public.legendfolio_dice_reads rd on rd.campaign_id=ca.id and rd.user_id=u
   where ca.owner_id=u and ca.deleted_at is null and (p_campaign_id is null or ca.id=p_campaign_id) and (before_id is null or d.id<before_id) order by d.id desc limit 20)x;
  return jsonb_build_object('items',response,'checked_at',now());
 end if;
 if p_action is distinct from 'roll' then raise exception 'Unknown dice action';end if;
 select * into c from public.legendfolio_campaigns where id=p_campaign_id and deleted_at is null for share;
 if c.id is null then raise exception 'Campaign unavailable' using errcode='42501';end if;
 request:=(p_payload->>'request_id')::uuid;if request is null then raise exception 'A roll request ID is required';end if;
 -- Lock a request across devices/retries so the same click can never generate two rolls.
 perform pg_advisory_xact_lock(hashtextextended(u::text||request::text,0));
 select * into r from public.legendfolio_dice_rolls where user_id=u and request_id=request;
 if r.id is not null then
  if r.campaign_id<>c.id or r.request_data<>p_payload then raise exception 'This request ID belongs to another roll';end if;
  return jsonb_build_object('id',r.id,'result',r.result,'created_at',r.created_at,'character_name',r.character_name,'player_name',r.player_name);
 end if;
 if (select count(*) from public.legendfolio_dice_rolls where user_id=u and created_at>now()-interval '1 minute')>=60 then raise exception 'Too many rolls. Wait a minute before rolling again.';end if;
 if c.owner_id=u then character_name:='Dungeon Master';
 else
  select * into m from public.legendfolio_memberships where id=(p_payload->>'membership_id')::uuid and campaign_id=c.id and user_id=u and status='approved';
  if m.id is null then raise exception 'Choose your approved campaign character' using errcode='42501';end if;
  character_name:=left(coalesce(nullif(m.shared_summary->>'name',''),'Character'),160);
 end if;
 player_name:=left(coalesce(nullif((select display_name from public.legendfolio_profiles where id=u),''),case when c.owner_id=u then 'Dungeon Master' else 'Player' end),160);
 dice:=p_payload->'dice';mode:=coalesce(p_payload->>'mode','normal');label:=trim(coalesce(p_payload->>'label',''));modifier:=coalesce((p_payload->>'modifier')::int,0);
 if jsonb_typeof(dice) is distinct from 'array' then raise exception 'Choose dice';end if;
 if jsonb_array_length(dice) not between 1 and 7 or mode not in ('normal','advantage','disadvantage') or abs(modifier::bigint)>9999 or length(label)>120 then raise exception 'Invalid dice settings';end if;
 for piece in select * from jsonb_array_elements(dice) loop
  sides:=(piece->>'sides')::int;n:=(piece->>'count')::int;
  if sides is null or n is null or sides not in (4,6,8,10,12,20,100) or n not between 1 and 50 or sides=any(seen) then raise exception 'Use 1 to 50 standard dice without duplicate groups';end if;
  selected:=selected+n;if selected>50 then raise exception 'Use at most 50 dice';end if;seen:=array_append(seen,sides);
  if mode<>'normal' and (jsonb_array_length(dice)<>1 or sides<>20 or n<>1) then raise exception 'Advantage and disadvantage require a single d20';end if;
  formula:=formula||case when formula='' then '' else ' + ' end||n::text||'d'||sides::text;
  rolls:='[]';subtotal:=0;
  for j in 1..case when mode='normal' then n else 2 end loop
   value:=floor(random()*sides)::int+1;rolls:=rolls||jsonb_build_array(value);physical:=physical+1;
   if mode='normal' then subtotal:=subtotal+value;elsif j=1 then subtotal:=value;elsif mode='advantage' then subtotal:=greatest(subtotal,value);else subtotal:=least(subtotal,value);end if;
  end loop;
  groups:=groups||jsonb_build_array(jsonb_build_object('sides',sides,'count',n,'rolls',rolls,'subtotal',subtotal));total:=total+subtotal;
 end loop;
 if modifier<>0 then formula:=formula||case when modifier>0 then ' + ' else ' - ' end||abs(modifier)::text;end if;
 response:=jsonb_build_object('formula',formula,'groups',groups,'modifier',modifier,'mode',mode,'total',total+modifier,'dice_count',physical,'selected_count',selected,'label',label,'source','server');
 insert into public.legendfolio_dice_rolls(campaign_id,user_id,request_id,request_data,character_name,player_name,result) values(c.id,u,request,p_payload,character_name,player_name,response) returning * into r;
 insert into public.legendfolio_activity(campaign_id,recipient_id,actor_id,kind,message) values(c.id,u,u,'dice',character_name||' rolled '||formula||' = '||(total+modifier)::text||' ('||physical::text||' dice).');
 return jsonb_build_object('id',r.id,'result',r.result,'created_at',r.created_at,'character_name',r.character_name,'player_name',r.player_name);
end $$;
revoke all on function public.legendfolio_dice(text,uuid,jsonb) from public,anon;
grant execute on function public.legendfolio_dice(text,uuid,jsonb) to authenticated;
commit;
