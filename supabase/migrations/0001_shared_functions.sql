-- Migration 0001: Shared functions and triggers
-- Feature: CORE (always required)
-- Run this first — all other migrations depend on these.

-- ─────────────────────────────────────────
-- set_updated_at()
-- Automatically stamps updated_at on any UPDATE.
-- Apply to every table that has an updated_at column.
-- ─────────────────────────────────────────
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- ─────────────────────────────────────────
-- handle_new_user()
-- Auto-creates a profile row whenever a new auth.users row is inserted.
-- Pulls full_name and avatar_url from OAuth metadata if present.
-- ─────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, avatar_url)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;
