-- Migration 0002: profiles
-- Extended user data. One row per auth.users row, created automatically on signup.

create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text,
  full_name   text,
  avatar_url  text,
  timezone    text default 'UTC',
  locale      text default 'en',
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- RLS
alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Auto-create profile row on new signup
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Auto-stamp updated_at
create trigger set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();
