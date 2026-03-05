# Environments (Solo Dev): Dev + Prod

This project can run with only two environments:
- `development`
- `production`

This is the recommended setup for a solo developer who wants low complexity and stable URLs.

## 1) Environment Model

## Development
- Supabase: one stable dev project (recommended: Supabase Cloud dev project URL)
- Backend: local backend (`localhost:3000`) and optional ngrok for physical iOS testing
- iOS app: points to dev Supabase + dev backend

## Production
- Supabase: separate prod project
- Backend: deployed API (e.g., Hetzner)
- iOS app: points to prod Supabase + prod backend

Important:
- Never point dev app to prod Supabase.
- Keep auth providers (Google, Apple) configured in both Supabase projects.

## 2) Backend Configuration

Backend env parsing is centralized in `backend/src/types/env.ts`.

Use:
- Local dev: `backend/.env`
- Production: server-level environment variables (systemd, Docker secrets, Fly secrets, etc.)

Minimum variables:
- `NODE_ENV` (`development` or `production`)
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

Example local dev values (`backend/.env`):

```env
NODE_ENV=development
PORT=3000
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8081

SUPABASE_URL=https://<your-dev-project>.supabase.co
SUPABASE_ANON_KEY=<dev-anon-or-publishable-key>
SUPABASE_SERVICE_ROLE_KEY=<dev-service-role-key>
```

## 3) iOS Configuration

iOS env loading is centralized in:
- `ios/AppTemplate/AppTemplate/App/AppEnvironment.swift`

Current setup uses a bundled env file:
- `ios/AppTemplate/AppTemplate/Env` (gitignored, real secrets)
- `ios/AppTemplate/AppTemplate/Env.example` (tracked template)

Recommended values:

### Dev (physical device friendly)

```env
SUPABASE_URL=https://<your-dev-project>.supabase.co
SUPABASE_ANON_KEY=<dev-publishable-or-anon-key>
BACKEND_URL=https://<dev-backend-or-ngrok-url>
```

### Prod

```env
SUPABASE_URL=https://<your-prod-project>.supabase.co
SUPABASE_ANON_KEY=<prod-publishable-or-anon-key>
BACKEND_URL=https://api.yourdomain.com
```

## 4) Google OAuth Checklist (Both Environments)

For each Supabase project (`dev`, `prod`):
- Enable Google provider
- Set provider client/secret
- Ensure callback URL is valid for that Supabase project:
  - `https://<project-ref>.supabase.co/auth/v1/callback`

In iOS:
- `GOOGLE_CLIENT_ID` must be iOS client ID
- `GOOGLE_WEB_CLIENT_ID` must be web client ID used by Supabase Google provider
- URL scheme in `Info.plist` must match iOS client ID reversed format

## 5) About the `/auth/v1/*` Proxy in Backend

There is a dev-only route in `backend/src/app.ts`:
- `app.all('/auth/v1/*', ...)` inside `if (env.NODE_ENV === 'development')`

Purpose:
- Temporary workaround for local physical-device testing when Supabase is local-only.

Long-term recommendation:
- Use a stable public Supabase URL for dev and prod.
- Once you do that, the proxy becomes optional and can be removed.

## 6) Deployment Plan (Simple)

1. Create/confirm two Supabase projects: `dev`, `prod`.
2. Deploy backend to Hetzner for prod (stable domain).
3. Keep backend local for dev (or deploy a dev instance if preferred).
4. Set iOS dev/prod env values to matching Supabase + backend URLs.
5. Verify login flow on simulator and physical device in both environments.

## 7) Operational Rules

- Use separate keys for dev and prod.
- Keep `service_role` key server-side only.
- Do not commit real env files.
- Rotate keys immediately if they are exposed.

## 8) Quick Verification Commands

Verify Supabase auth endpoint:

```bash
curl -i https://<project-ref>.supabase.co/auth/v1/settings
```

Verify backend health:

```bash
curl -i https://api.yourdomain.com/health
```

If both are reachable and iOS env points to them, auth flow should work on physical devices without local-network workarounds.
