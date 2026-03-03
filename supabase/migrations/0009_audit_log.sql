-- Migration 0009: audit_log
-- Immutable log of sensitive user actions. Service role only.
-- Used for: subscription changes, account deletion, data exports, admin actions.
-- No RLS — never exposed to users. Backend writes via service_role.

create table public.audit_log (
  id         bigint generated always as identity primary key,
  user_id    uuid references auth.users(id),  -- nullable: system-level events have no user
  action     text not null,                   -- e.g. 'subscription.cancelled', 'account.deleted'
  metadata   jsonb,                           -- structured context for the action
  ip_address inet,
  user_agent text,
  created_at timestamptz default now()
);

create index on public.audit_log(user_id);
create index on public.audit_log(created_at);

-- No RLS — internal only via service_role.
-- Never grant SELECT to authenticated or anon roles.
