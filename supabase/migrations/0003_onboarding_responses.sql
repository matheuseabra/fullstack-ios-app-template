-- Migration 0003: onboarding_responses
-- Stores quiz answers from the onboarding flow. One row per question per user.
-- answer is jsonb to support strings, arrays, numbers, and booleans.

create table public.onboarding_responses (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  question_key text not null,   -- e.g. 'primary_goal', 'commitment', 'name'
  answer       jsonb not null,  -- flexible: "Option A", ["A","B"], 10, true
  created_at   timestamptz default now()
);

create index on public.onboarding_responses(user_id);

-- RLS
alter table public.onboarding_responses enable row level security;

create policy "Users can manage own onboarding responses"
  on public.onboarding_responses for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
