-- Migration 0010: tasks
-- Feature: TASKS (domain feature — always required for this template)
-- User tasks for the task manager feature. Supports local-first + server sync.

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

-- RLS
alter table public.tasks enable row level security;

create policy "Users can view own tasks"
  on public.tasks for select
  using (auth.uid() = user_id);

create policy "Users can insert own tasks"
  on public.tasks for insert
  with check (auth.uid() = user_id);

create policy "Users can update own tasks"
  on public.tasks for update
  using (auth.uid() = user_id);

create policy "Users can delete own tasks"
  on public.tasks for delete
  using (auth.uid() = user_id);

-- Auto-stamp updated_at
create trigger set_tasks_updated_at
  before update on public.tasks
  for each row execute function public.set_updated_at();
