-- seed.sql
-- Local development seed data.
-- Run after all migrations via: supabase db reset
-- Or paste into Studio SQL editor after migrations are applied.
--
-- NOTE: This creates a test user directly in auth.users.
-- The on_auth_user_created trigger will auto-create the profiles row.

-- ─────────────────────────────────────────
-- Test user
-- ─────────────────────────────────────────
insert into auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  role
) values (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'test@example.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Test User","avatar_url":""}',
  false,
  'authenticated'
) on conflict (id) do nothing;

-- ─────────────────────────────────────────
-- Sample onboarding responses
-- ─────────────────────────────────────────
insert into public.onboarding_responses (user_id, question_key, answer) values
  ('00000000-0000-0000-0000-000000000001', 'name',        '"Test User"'),
  ('00000000-0000-0000-0000-000000000001', 'primary_goal', '"Option A"'),
  ('00000000-0000-0000-0000-000000000001', 'commitment',   '"10 min"')
on conflict do nothing;

-- ─────────────────────────────────────────
-- Sample subscription (free tier)
-- ─────────────────────────────────────────
insert into public.subscriptions (user_id, revenuecat_user_id, status, entitlements) values
  (
    '00000000-0000-0000-0000-000000000001',
    'rc_00000000-0000-0000-0000-000000000001',
    'free',
    '[]'::jsonb
  )
on conflict (revenuecat_user_id) do nothing;

-- ─────────────────────────────────────────
-- Sample notification preferences
-- ─────────────────────────────────────────
insert into public.notification_preferences (user_id, enabled, reminder_time, days_of_week) values
  ('00000000-0000-0000-0000-000000000001', true, '09:00:00', '{1,2,3,4,5}')
on conflict (user_id) do nothing;

-- ─────────────────────────────────────────
-- Sample user settings
-- ─────────────────────────────────────────
insert into public.user_settings (user_id, key, value) values
  ('00000000-0000-0000-0000-000000000001', 'theme',                '"system"'),
  ('00000000-0000-0000-0000-000000000001', 'onboarding_complete',  'true'),
  ('00000000-0000-0000-0000-000000000001', 'haptics_enabled',      'true')
on conflict (user_id, key) do nothing;
