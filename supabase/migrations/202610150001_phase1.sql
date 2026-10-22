-- Legendfolio Phase 1 only. Additive names avoid overwriting existing application tables.
-- Review and apply this migration in the EXISTING Supabase project.
begin;
create table public.legendfolio_profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default '' check (char_length(display_name)<=80),
 avatar_url text check (avatar_url is null or avatar_url ~ '^https://'),
 preferences jsonb not null default '{}'::jsonb check (jsonb_typeof(preferences)='object' and octet_length(preferences::text)<=32768),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.legendfolio_characters (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 character_name text not null check (char_length(character_name) between 1 and 160),
 game_system text not null default 'dnd5e' check (char_length(game_system) between 1 and 80),
 character_data jsonb not null,
 revision bigint not null default 1 check (revision>0),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 constraint legendfolio_valid_character check (coalesce(
 jsonb_typeof(character_data)='object' and
 character_data->>'format'='strixhaven-living-v1' and
 jsonb_typeof(character_data->'fields')='object' and
 jsonb_typeof(character_data->'art')='object' and
 jsonb_typeof(character_data->'notes')='object' and
 octet_length(character_data::text)<=16777216
 ,false))
);
create index legendfolio_characters_owner_modified on public.legendfolio_characters(owner_id,updated_at desc);
alter table public.legendfolio_profiles enable row level security;
alter table public.legendfolio_profiles force row level security;
alter table public.legendfolio_characters enable row level security;
alter table public.legendfolio_characters force row level security;
revoke all on public.legendfolio_profiles,public.legendfolio_characters from anon,authenticated;
grant select,insert,update on public.legendfolio_profiles to authenticated;
grant select,insert,update,delete on public.legendfolio_characters to authenticated;
create policy lf_profiles_read_own on public.legendfolio_profiles for select to authenticated using ((select auth.uid())=id);
create policy lf_profiles_create_own on public.legendfolio_profiles for insert to authenticated with check ((select auth.uid())=id);
create policy lf_profiles_edit_own on public.legendfolio_profiles for update to authenticated using ((select auth.uid())=id) with check ((select auth.uid())=id);
create policy lf_characters_read_own on public.legendfolio_characters for select to authenticated using ((select auth.uid())=owner_id);
create policy lf_characters_create_own on public.legendfolio_characters for insert to authenticated with check ((select auth.uid())=owner_id);
create policy lf_characters_edit_own on public.legendfolio_characters for update to authenticated using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
create policy lf_characters_delete_own on public.legendfolio_characters for delete to authenticated using ((select auth.uid())=owner_id);
create function public.legendfolio_stamp_character() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if tg_op='UPDATE' then
  if new.owner_id<>old.owner_id or new.id<>old.id then raise exception 'Character ownership and identity are immutable' using errcode='42501';end if;
  new.created_at=old.created_at;new.revision=old.revision+1;
 else new.revision=1;new.created_at=now();end if;
 new.updated_at=now();return new;
end $$;
create trigger lf_character_stamp before insert or update on public.legendfolio_characters for each row execute function public.legendfolio_stamp_character();
create function public.legendfolio_stamp_profile() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if tg_op='UPDATE' then
  if new.id<>old.id then raise exception 'Profile identity is immutable' using errcode='42501';end if;
  new.created_at=old.created_at;
 else new.created_at=now();end if;
 new.updated_at=now();return new;
end $$;
create trigger lf_profile_stamp before insert or update on public.legendfolio_profiles for each row execute function public.legendfolio_stamp_profile();
-- RLS still applies inside this SECURITY INVOKER function. No service-role key is needed.
create function public.legendfolio_save_character(p_id uuid,p_expected_revision bigint,p_character_name text,p_game_system text,p_character_data jsonb)
returns setof public.legendfolio_characters language plpgsql security invoker set search_path='' as $$
declare result public.legendfolio_characters;
begin
 if auth.uid() is null then raise exception 'Sign in to save characters' using errcode='28000';end if;
 if p_id is null then
  if p_expected_revision is not null then raise exception 'New characters have no previous revision' using errcode='22023';end if;
  insert into public.legendfolio_characters(owner_id,character_name,game_system,character_data)
  values(auth.uid(),p_character_name,p_game_system,p_character_data) returning * into result;
 else
  if p_expected_revision is null then raise exception 'Review the existing cloud revision before replacing it' using errcode='22023';end if;
  update public.legendfolio_characters set character_name=p_character_name,game_system=p_game_system,character_data=p_character_data
  where id=p_id and owner_id=auth.uid() and revision=p_expected_revision returning * into result;
  if not found then raise exception 'Cloud version changed or character is unavailable. Reload and compare.' using errcode='40001';end if;
 end if;
 return next result;
end $$;
revoke all on function public.legendfolio_save_character(uuid,bigint,text,text,jsonb) from public,anon;
grant execute on function public.legendfolio_save_character(uuid,bigint,text,text,jsonb) to authenticated;
revoke all on function public.legendfolio_stamp_character(),public.legendfolio_stamp_profile() from public,anon,authenticated;
comment on table public.legendfolio_characters is 'Phase 1 private account-owned records. No online campaign membership or DM permissions are implemented.';
commit;
