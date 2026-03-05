-- Migration 0006: user_settings
-- Feature: CORE (always required)
-- Key-value store for arbitrary per-user app settings.
-- Composite primary key (user_id, key) — use upsert to write.

create table public.user_settings (
  user_id    uuid not null references auth.users(id) on delete cascade,
  key        text not null,   -- e.g. 'theme', 'language', 'onboarding_complete'
  value      jsonb not null,  -- e.g. '"dark"', 'true', '{"haptics": true}'
  updated_at timestamptz default now(),
  primary key (user_id, key)
);

-- RLS
alter table public.user_settings enable row level security;

create policy "Users can manage own settings"
  on public.user_settings for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
