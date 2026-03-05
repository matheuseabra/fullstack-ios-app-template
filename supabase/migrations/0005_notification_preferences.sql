-- Migration 0005: notification_preferences
-- Feature: NOTIFICATIONS (ENABLE_NOTIFICATIONS)
-- Per-user notification config. One row per user, upserted during onboarding.

create table public.notification_preferences (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  enabled      boolean default true,
  reminder_time time default '09:00:00',      -- local time for daily reminder
  days_of_week  int[] default '{1,2,3,4,5}',  -- 0=Sun, 1=Mon, ..., 6=Sat
  push_token   text,                           -- APNs device token
  updated_at   timestamptz default now()
);

create unique index on public.notification_preferences(user_id);

-- RLS
alter table public.notification_preferences enable row level security;

create policy "Users can manage own notification prefs"
  on public.notification_preferences for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Auto-stamp updated_at
create trigger set_updated_at
  before update on public.notification_preferences
  for each row execute function public.set_updated_at();
