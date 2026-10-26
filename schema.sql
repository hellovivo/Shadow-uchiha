-- SHADOW UCHIHA starter schema. Review before use.
-- This schema does not provide video storage and does not use Firebase.
create extension if not exists pgcrypto;
create type public.account_role as enum ('user','admin','owner');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role public.account_role not null default 'user',
  created_at timestamptz not null default now()
);
create table public.anime (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  title text not null,
  synopsis text not null default '',
  poster_url text,
  banner_url text,
  release_year integer,
  genres text[] not null default '{}',
  status text not null default 'draft' check(status in ('draft','published')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);
create table public.episodes (
  id uuid primary key default gen_random_uuid(),
  anime_id uuid not null references public.anime(id) on delete cascade,
  season_number integer not null default 1 check(season_number > 0),
  episode_number integer not null check(episode_number > 0),
  title text not null,
  stream_url text,
  status text not null default 'draft' check(status in ('draft','published')),
  unique(anime_id, season_number, episode_number)
);
create table public.user_lists (
  user_id uuid not null references auth.users(id) on delete cascade,
  anime_id uuid not null references public.anime(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_id, anime_id)
);
create table public.admin_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  reason text not null default '',
  status text not null default 'pending' check(status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles(id, display_name, role)
  values(new.id, nullif(new.raw_user_meta_data ->> 'display_name',''), 'user')
  on conflict(id) do nothing;
  return new;
end;
$$;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.current_role()
returns public.account_role language sql stable security definer set search_path = ''
as $$ select role from public.profiles where id = auth.uid() $$;
create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = ''
as $$ select coalesce(public.current_role() in ('admin','owner'), false) $$;
create or replace function public.is_owner()
returns boolean language sql stable security definer set search_path = ''
as $$ select coalesce(public.current_role() = 'owner', false) $$;

alter table public.profiles enable row level security;
alter table public.anime enable row level security;
alter table public.episodes enable row level security;
alter table public.user_lists enable row level security;
alter table public.admin_requests enable row level security;

create policy "profile self read" on public.profiles for select to authenticated
using(id = auth.uid() or public.is_owner());
create policy "profile self update no role escalation" on public.profiles for update to authenticated
using(id = auth.uid()) with check(id = auth.uid() and role = public.current_role());
create policy "owner manages profiles" on public.profiles for all to authenticated
using(public.is_owner()) with check(public.is_owner());

create policy "published anime or staff read" on public.anime for select to anon, authenticated
using(status = 'published' or public.is_staff());
create policy "staff insert anime" on public.anime for insert to authenticated
with check(public.is_staff() and created_by = auth.uid());
create policy "staff update anime" on public.anime for update to authenticated
using(public.is_staff()) with check(public.is_staff());
create policy "staff delete anime" on public.anime for delete to authenticated
using(public.is_staff());

create policy "published episodes or staff read" on public.episodes for select to anon, authenticated
using((status = 'published' and exists(select 1 from public.anime a where a.id = anime_id and a.status = 'published')) or public.is_staff());
create policy "staff insert episodes" on public.episodes for insert to authenticated with check(public.is_staff());
create policy "staff update episodes" on public.episodes for update to authenticated using(public.is_staff()) with check(public.is_staff());
create policy "staff delete episodes" on public.episodes for delete to authenticated using(public.is_staff());

create policy "user manages own list" on public.user_lists for all to authenticated
using(user_id = auth.uid()) with check(user_id = auth.uid());
create policy "read own requests or owner" on public.admin_requests for select to authenticated
using(user_id = auth.uid() or public.is_owner());
create policy "create own pending request" on public.admin_requests for insert to authenticated
with check(user_id = auth.uid() and status = 'pending');
create policy "owner reviews requests" on public.admin_requests for update to authenticated
using(public.is_owner()) with check(public.is_owner());

-- SECURITY NOTE:
-- This starter schema is not production-complete. Before public launch, implement and test
-- a trusted server-side approval function that enforces a maximum of two privileged accounts
-- including the owner, writes an audit log, and prevents role changes outside that function.
-- Create the first owner only through a trusted SQL editor after signup; never expose role
-- assignment in the public UI. Do not place service-role keys in client code.
