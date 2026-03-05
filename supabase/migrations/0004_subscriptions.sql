-- Migration 0004: subscriptions
-- Feature: SUBSCRIPTIONS / PAYWALL (ENABLE_SUBSCRIPTIONS)
-- Mirrors RevenueCat webhook data. Users can read their own row.
-- Only the backend service_role can write (via RevenueCat webhook handler).

create table public.subscriptions (
  id                   uuid primary key default gen_random_uuid(),
  user_id              uuid not null references auth.users(id) on delete cascade,
  revenuecat_user_id   text unique not null,
  product_id           text,                         -- e.g. 'pro_yearly', 'pro_monthly'
  status               text not null default 'free', -- free | trial | active | expired | cancelled
  trial_ends_at        timestamptz,
  current_period_end   timestamptz,
  cancel_at_period_end boolean default false,
  entitlements         jsonb default '[]'::jsonb,    -- e.g. '["premium","ai_features"]'
  created_at           timestamptz default now(),
  updated_at           timestamptz default now()
);

create index on public.subscriptions(user_id);
create index on public.subscriptions(revenuecat_user_id);

-- RLS
alter table public.subscriptions enable row level security;

-- Users can READ their own subscription status — never write directly
create policy "Users can view own subscription"
  on public.subscriptions for select
  using (auth.uid() = user_id);

-- No insert/update/delete policy for users.
-- Backend writes via service_role key in the RevenueCat webhook handler.

-- Auto-stamp updated_at
create trigger set_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();
