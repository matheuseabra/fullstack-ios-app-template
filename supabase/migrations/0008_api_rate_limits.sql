-- Migration 0008: api_rate_limits
-- Stores sliding-window rate limit state per (user, endpoint).
-- Redis is the primary store; this table is the fallback and persistence layer.
-- No RLS — fully internal, only accessible via service_role.

create table public.api_rate_limits (
  user_id      uuid not null references auth.users(id) on delete cascade,
  endpoint     text not null,
  count        integer default 0,
  window_start timestamptz default now(),
  primary key (user_id, endpoint)
);

-- No RLS — service_role only. Never exposed to anon or authenticated roles.
