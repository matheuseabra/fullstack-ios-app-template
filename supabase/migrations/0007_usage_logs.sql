-- Migration 0007: usage_logs
-- Tracks per-user feature usage for cap enforcement and analytics.
-- Only the backend (service_role) inserts rows. Users can read for UI display.

create table public.usage_logs (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  feature    text not null,      -- e.g. 'ai_generation', 'export', 'report'
  count      integer default 1,
  metadata   jsonb,              -- optional context (e.g. model used, file size)
  created_at timestamptz default now()
);

create index on public.usage_logs(user_id, feature, created_at);

-- RLS
alter table public.usage_logs enable row level security;

-- Users can read their own usage (to show remaining quota in UI)
create policy "Users can view own usage"
  on public.usage_logs for select
  using (auth.uid() = user_id);

-- No insert/update/delete for users — backend writes via service_role
