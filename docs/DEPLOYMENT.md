# Deployment Guide

This guide covers the production deployment path for the backend, data layer, and iOS release inputs.

## Prerequisites

- Fly.io app created for the backend.
- Supabase production project created.
- RevenueCat project created with production products.
- PostHog production project created.
- Apple Developer account, App Store Connect app, and App Store Connect API key ready.

## Backend Production Environment

Set these on Fly.io before the first production deploy:

```bash
fly secrets set \
  NODE_ENV=production \
  PORT=3000 \
  ALLOWED_ORIGINS=https://your-web-domain.example,https://api.your-domain.example \
  SUPABASE_URL=https://<project-ref>.supabase.co \
  SUPABASE_ANON_KEY=<anon-key> \
  SUPABASE_SERVICE_ROLE_KEY=<service-role-key> \
  REVENUECAT_WEBHOOK_SECRET=<webhook-secret> \
  REVENUECAT_API_KEY=<revenuecat-api-key> \
  POSTHOG_API_KEY=<posthog-project-key> \
  POSTHOG_HOST=https://us.i.posthog.com
```

Notes:

- `ALLOWED_ORIGINS` must be explicitly set in production.
- Do not use `*` in `ALLOWED_ORIGINS`.
- Do not deploy with `REVENUECAT_WEBHOOK_SECRET=your_*` placeholder values.

## Supabase Production Setup

1. Link the CLI to the production project.

```bash
supabase link --project-ref <project-ref>
```

2. Apply all migrations.

```bash
supabase db push
```

3. Confirm critical tables exist and row-level security is enabled.

```sql
select schemaname, tablename, rowsecurity
from pg_tables
where schemaname = 'public'
order by tablename;
```

4. Confirm backup and restore ownership.

## Fly.io Deployment

Deploy the backend:

```bash
cd backend
fly deploy
```

Validate after deploy:

```bash
curl https://<fly-app>.fly.dev/health
```

Expected response:

```json
{"status":"ok","ts":1700000000000}
```

Review live logs:

```bash
fly logs
```


## RevenueCat Setup (via MCP)

Use RevenueCat MCP to automate all RevenueCat setup:

- **Project:** Create a new RevenueCat project for this app using MCP.
- **Products:** Define all subscription products (monthly, yearly, lifetime) with MCP, matching App Store Connect product IDs.
- **Entitlements:** Set up entitlements (e.g., "Pro") via MCP.
- **Webhook:** Configure the webhook via MCP to point to your backend endpoint:

  ```text
  https://<fly-app>.fly.dev/auth/webhook/revenuecat
  ```

- **Webhook secret:** Store the generated secret in Fly.io secrets and backend config.

After MCP configuration:

- Send a test webhook from RevenueCat (MCP can trigger this).
- Verify the endpoint returns `200` for valid requests.
- Verify invalid signatures return `401`.
- Confirm subscription rows are updated in Supabase.

## iOS Production Inputs

Before archiving the app, confirm:

- The Release configuration points to production `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `BACKEND_URL`.
- The production bundle id matches App Store Connect.
- Release entitlements include the correct push environment.
- Release legal links point to live policy URLs.

## Secrets Management

- Keep backend secrets in Fly.io secrets or another secret manager.
- Keep iOS release secrets out of git; ship only examples or build-time injection.
- Rotate any secret that was ever committed, shared, or exposed in logs.
- Record owners for Supabase, RevenueCat, PostHog, and App Store Connect credentials.

## Rollback

Backend rollback:

```bash
fly releases
fly rollback <RELEASE_ID>
```

iOS rollback:

- Pause rollout in App Store Connect if release is staged.
- Disable external TestFlight group rollout if the issue is only in beta.
- Prepare a hotfix build with an incremented build number.