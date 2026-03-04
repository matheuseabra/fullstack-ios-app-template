# Database Schema

> Supabase (Postgres) — all tables use RLS by default. Users can only read/write their own data.

## Design Principles

1. **RLS on every table** — no exceptions
2. **`user_id` foreign key** on every user-owned table → `auth.users(id)`
3. **`created_at` / `updated_at`** on every table via trigger
4. **Soft deletes** with `deleted_at` where data history matters
5. **UUID primary keys** throughout
6. **Never expose internal tables** (subscriptions, audit logs) to client RLS write policies

---

## Core Tables (Always Present)

### `profiles`
Extended user data beyond what Supabase auth provides.

```sql
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

-- Auto-create profile on signup
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

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

---

### `onboarding_responses`
Stores answers from the onboarding quiz. Drives personalization.

```sql
create table public.onboarding_responses (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  question_key text not null,       -- e.g. 'primary_goal', 'experience_level'
  answer      jsonb not null,       -- flexible: string, array, number
  created_at  timestamptz default now()
);

create index on public.onboarding_responses(user_id);

alter table public.onboarding_responses enable row level security;

create policy "Users can manage own onboarding responses"
  on public.onboarding_responses for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

---

### `subscriptions`
Mirrors RevenueCat webhook data. **Read-only for users** — only service role can write.

```sql
create table public.subscriptions (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references auth.users(id) on delete cascade,
  revenuecat_user_id    text unique not null,
  product_id            text,                    -- e.g. 'pro_yearly', 'pro_monthly'
  status                text not null default 'free',  -- free | trial | active | expired | cancelled
  trial_ends_at         timestamptz,
  current_period_end    timestamptz,
  cancel_at_period_end  boolean default false,
  entitlements          jsonb default '[]',      -- ['premium', 'ai_features']
  created_at            timestamptz default now(),
  updated_at            timestamptz default now()
);

create index on public.subscriptions(user_id);
create index on public.subscriptions(revenuecat_user_id);

alter table public.subscriptions enable row level security;

-- Users can READ their own subscription — NEVER WRITE
create policy "Users can view own subscription"
  on public.subscriptions for select
  using (auth.uid() = user_id);

-- No insert/update/delete policy for users
-- Only service_role (backend) can write via webhook handler
```

---

### `notification_preferences`
Per-user notification config set during onboarding.

```sql
create table public.notification_preferences (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  enabled      boolean default true,
  reminder_time time default '09:00:00',    -- local time for daily reminder
  days_of_week int[] default '{1,2,3,4,5}', -- 0=Sun, 1=Mon, ...
  push_token   text,                         -- APNs device token
  updated_at   timestamptz default now()
);

create unique index on public.notification_preferences(user_id);

alter table public.notification_preferences enable row level security;

create policy "Users can manage own notification prefs"
  on public.notification_preferences for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

---

### `user_settings`
Key-value settings store. Flexible for any app config.

```sql
create table public.user_settings (
  user_id     uuid not null references auth.users(id) on delete cascade,
  key         text not null,
  value       jsonb not null,
  updated_at  timestamptz default now(),
  primary key (user_id, key)
);

alter table public.user_settings enable row level security;

create policy "Users can manage own settings"
  on public.user_settings for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

---

### `usage_logs`
Tracks feature usage for cap enforcement and analytics.

```sql
create table public.usage_logs (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  feature     text not null,        -- e.g. 'ai_generation', 'export'
  count       integer default 1,
  metadata    jsonb,
  created_at  timestamptz default now()
);

create index on public.usage_logs(user_id, feature, created_at);

alter table public.usage_logs enable row level security;

-- Users can read their own usage (for showing limits in UI)
create policy "Users can view own usage"
  on public.usage_logs for select
  using (auth.uid() = user_id);

-- Only backend (service_role) inserts usage logs
```

---

### `api_rate_limits`
Stores rate limit state per user+endpoint. Redis is primary; this is fallback/persistence.

```sql
create table public.api_rate_limits (
  user_id     uuid not null references auth.users(id) on delete cascade,
  endpoint    text not null,
  count       integer default 0,
  window_start timestamptz default now(),
  primary key (user_id, endpoint)
);

-- No RLS needed — only accessible via service_role
```

---

### `audit_log`
Immutable record of sensitive actions. Service role only.

```sql
create table public.audit_log (
  id          bigint generated always as identity primary key,
  user_id     uuid references auth.users(id),
  action      text not null,         -- 'subscription.cancelled', 'account.deleted', etc.
  metadata    jsonb,
  ip_address  inet,
  user_agent  text,
  created_at  timestamptz default now()
);

create index on public.audit_log(user_id);
create index on public.audit_log(created_at);

-- No user RLS — internal only via service_role
```

---

## Shared Triggers

```sql
-- Auto-update updated_at on any table
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Apply to all tables with updated_at:
create trigger set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger set_updated_at before update on public.subscriptions
  for each row execute function public.set_updated_at();

create trigger set_updated_at before update on public.notification_preferences
  for each row execute function public.set_updated_at();
```

---

## App-Specific Tables (Examples by Niche)

These extend the core schema. Add to `supabase/migrations/` per app.

### Education App
```sql
create table public.lessons (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  title       text not null,
  content     jsonb,
  completed   boolean default false,
  completed_at timestamptz,
  created_at  timestamptz default now()
);
```

### Health App
```sql
create table public.entries (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  type        text not null,       -- 'mood', 'workout', 'meal', etc.
  value       jsonb not null,
  notes       text,
  logged_at   timestamptz default now(),
  created_at  timestamptz default now()
);
```

---

## Implemented Feature Tables

> Tables that have been built and are active in this app. Update this section when adding features.

### `tasks`
User tasks for the Task Manager feature. Local-first — synced to Supabase in background.
Migration: `supabase/migrations/0010_tasks.sql`

```sql
create table public.tasks (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  title         text not null,
  note          text default '',
  is_completed  boolean default false,
  priority      text default 'medium' check (priority in ('low', 'medium', 'high')),
  due_date      timestamptz,
  completed_at  timestamptz,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

create index on public.tasks(user_id, due_date);
create index on public.tasks(user_id, is_completed);

alter table public.tasks enable row level security;

create policy "Users can view own tasks"
  on public.tasks for select using (auth.uid() = user_id);
create policy "Users can insert own tasks"
  on public.tasks for insert with check (auth.uid() = user_id);
create policy "Users can update own tasks"
  on public.tasks for update using (auth.uid() = user_id);
create policy "Users can delete own tasks"
  on public.tasks for delete using (auth.uid() = user_id);

create trigger set_tasks_updated_at
  before update on public.tasks
  for each row execute function public.set_updated_at();
```

**API:** `GET/POST /api/tasks`, `GET/PUT/DELETE /api/tasks/:id` (all authenticated)
**iOS SwiftData model:** `TaskItem` in `ios/Models/TaskItem.swift`
**Backend route:** `backend/src/routes/tasks.ts`
**Zod schema:** `backend/src/schemas/task.schema.ts`
