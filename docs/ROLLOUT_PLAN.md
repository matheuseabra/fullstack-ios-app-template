# Rollout Plan

> Phased implementation of the AppStudio Boilerplate — from documented specs to production-ready code.
>
> **Current state:** Phase 1 complete — scaffolding and infrastructure in place.
> **Target state:** Fully functional iOS app + Hono backend + Supabase database, deployed and shippable.

---

## Phase 1 — Project Scaffolding & Infrastructure

Foundation: project configs, tooling, Docker, environment templates.

- [x] Initialize `backend/package.json` with dependencies (hono, @hono/zod-validator, @hono/swagger-ui, hono-openapi, zod, pino, dotenv)
- [x] Initialize `backend/package.json` with dev dependencies (typescript, tsx, nodemon, jest, ts-jest, eslint, prettier, @types/node)
- [x] Add npm scripts: `dev`, `build`, `start`, `test`, `test:watch`, `lint`, `format`, `db:start`, `db:stop`, `db:push`, `db:reset`, `db:types`
- [x] Create `backend/tsconfig.json` (strict mode, ES2022 target, NodeNext module)
- [x] Create `backend/eslint.config.js` + `backend/.prettierrc`
- [x] Create `backend/.env.example` with all env vars (Supabase, RevenueCat, PostHog, Redis, R2)
- [x] Create `backend/.gitignore` (node_modules, dist, .env, coverage)
- [x] Create `backend/Dockerfile` (multi-stage: node:20-alpine builder → runtime)
- [x] Create `backend/docker-compose.yml` (api + redis services, Supabase via CLI)
- [x] Create `backend/fly.toml` (app config, auto_stop_machines, min_machines_running=0)
- [x] Create `supabase/config.toml` for local dev
- [x] Verify: `npm install` succeeds, `npm run build` produces empty dist, Docker builds

---

## Phase 2 — Database Layer

Core tables, RLS policies, triggers, indexes, and seed data.

### 2A — Shared Functions & Triggers
- [ ] Create migration `supabase/migrations/0001_shared_functions.sql`
  - `set_updated_at()` trigger function
  - `handle_new_user()` trigger function (auto-create profile on auth.users insert)

### 2B — Core Tables
- [ ] Create migration `supabase/migrations/0002_profiles.sql`
  - Table: `profiles` (id, email, full_name, avatar_url, timezone, locale, created_at, updated_at)
  - RLS: select own, update own
  - Trigger: `on_auth_user_created` → `handle_new_user()`
  - Trigger: `set_updated_at`
- [ ] Create migration `supabase/migrations/0003_onboarding_responses.sql`
  - Table: `onboarding_responses` (id, user_id, question_key, answer jsonb, created_at)
  - Index: `user_id`
  - RLS: all operations on own rows
- [ ] Create migration `supabase/migrations/0004_subscriptions.sql`
  - Table: `subscriptions` (id, user_id, revenuecat_user_id, product_id, status, trial_ends_at, current_period_end, cancel_at_period_end, entitlements jsonb, created_at, updated_at)
  - Indexes: `user_id`, `revenuecat_user_id` (unique)
  - RLS: select own only (no insert/update/delete for users — service_role only)
  - Trigger: `set_updated_at`
- [ ] Create migration `supabase/migrations/0005_notification_preferences.sql`
  - Table: `notification_preferences` (id, user_id, enabled, reminder_time, days_of_week, push_token, updated_at)
  - Unique index: `user_id`
  - RLS: all operations on own rows
  - Trigger: `set_updated_at`
- [ ] Create migration `supabase/migrations/0006_user_settings.sql`
  - Table: `user_settings` (user_id, key, value jsonb, updated_at) — composite PK
  - RLS: all operations on own rows
- [ ] Create migration `supabase/migrations/0007_usage_logs.sql`
  - Table: `usage_logs` (id, user_id, feature, count, metadata jsonb, created_at)
  - Index: `(user_id, feature, created_at)`
  - RLS: select own only (service_role inserts)
- [ ] Create migration `supabase/migrations/0008_api_rate_limits.sql`
  - Table: `api_rate_limits` (user_id, endpoint, count, window_start) — composite PK
  - No RLS (service_role only)
- [ ] Create migration `supabase/migrations/0009_audit_log.sql`
  - Table: `audit_log` (id bigint identity, user_id, action, metadata jsonb, ip_address inet, user_agent, created_at)
  - Indexes: `user_id`, `created_at`
  - No user RLS (service_role only)

### 2C — Seed & Types
- [ ] Create `supabase/seed.sql` with test user profile + sample data
- [ ] Verify: `supabase start` + `supabase db push` applies all migrations cleanly
- [ ] Run `supabase gen types typescript --local > backend/src/types/database.ts`

---

## Phase 3 — Backend Core

App entry point, middleware stack, service clients, shared libraries.

### 3A — Shared Libs
- [ ] Create `backend/src/lib/errors.ts` — AppError class with code, status, message
- [ ] Create `backend/src/lib/response.ts` — success/error JSON response helpers
- [ ] Create `backend/src/lib/logger.ts` — Pino logger setup

### 3B — Type Definitions
- [ ] Create `backend/src/types/index.ts` — shared TypeScript types (User, Subscription, etc.)
- [ ] Create `backend/src/types/env.ts` — Zod schema for env vars with typed parse

### 3C — Service Clients
- [ ] Create `backend/src/services/supabase.ts` — anon client + service_role client
- [ ] Create `backend/src/services/redis.ts` — Redis client (optional, graceful fallback)
- [ ] Create `backend/src/services/revenuecat.ts` — webhook signature validator + API client
- [ ] Create `backend/src/services/posthog.ts` — server-side event tracking client
- [ ] Create `backend/src/services/r2.ts` — Cloudflare R2 storage client (opt-in)

### 3D — Middleware
- [ ] Create `backend/src/middleware/auth.ts` — JWT verification via Supabase `getUser()`
- [ ] Create `backend/src/middleware/rateLimiter.ts` — sliding window (Redis primary, in-memory fallback)
- [ ] Create `backend/src/middleware/usageCap.ts` — per-user feature limits based on subscription tier
- [ ] Create `backend/src/middleware/requestLogger.ts` — structured request/response logging
- [ ] Create `backend/src/middleware/errorHandler.ts` — centralized error → JSON response mapping

### 3E — App Bootstrap
- [ ] Create `backend/src/app.ts` — Hono app with global middleware (CORS, logger, secureHeaders), OpenAPI/Swagger (dev), health check, route mounting, error handler
- [ ] Create `backend/src/index.ts` — entry point (env parse, app import, `serve()` on PORT)
- [ ] Verify: `npm run dev` starts server, `GET /health` returns `{ status: "ok" }`

---

## Phase 4 — Backend API Routes

All endpoints with Zod validation, per the backend/README.md spec.

### 4A — Schemas
- [ ] Create `backend/src/schemas/user.schema.ts` — profile update, settings CRUD
- [ ] Create `backend/src/schemas/onboarding.schema.ts` — quiz response submission
- [ ] Create `backend/src/schemas/subscription.schema.ts` — RevenueCat webhook payload
- [ ] Create `backend/src/schemas/usage.schema.ts` — usage check/log
- [ ] Create `backend/src/schemas/notification.schema.ts` — push token + preferences

### 4B — Route Handlers
- [ ] Create `backend/src/routes/auth.ts` — public webhook/callback handlers
- [ ] Create `backend/src/routes/users.ts`
  - `GET /api/users/me` — get own profile
  - `PUT /api/users/me` — update profile
  - `GET /api/users/me/settings` — get settings
  - `PUT /api/users/me/settings` — upsert setting by key
- [ ] Create `backend/src/routes/onboarding.ts`
  - `POST /api/onboarding/responses` — save quiz answers (batch)
- [ ] Create `backend/src/routes/subscriptions.ts`
  - `POST /auth/webhook/revenuecat` — RevenueCat webhook (signature-verified, service_role write)
  - `GET /api/subscriptions/me` — get own subscription status
- [ ] Create `backend/src/routes/usage.ts`
  - `GET /api/usage/:feature` — check remaining usage for feature
  - `POST /api/usage/:feature` — log usage event
- [ ] Create `backend/src/routes/notifications.ts`
  - `PUT /api/notifications/token` — register/update APNs push token
  - `GET /api/notifications/preferences` — get notification prefs
  - `PUT /api/notifications/preferences` — update notification prefs

### 4C — Route Mounting & Verification
- [ ] Mount all routes in `app.ts` (public: `/auth/*`, protected: `/api/*`)
- [ ] Apply `authMiddleware` + `rateLimiter` to `/api/*`
- [ ] Verify: all routes respond correctly with mock/manual testing
- [ ] Run `npm run lint` — zero errors

---

## Phase 5 — Backend Testing & CI/CD

Jest test suite + GitHub Actions pipelines.

### 5A — Test Setup
- [ ] Create `backend/jest.config.ts` (ts-jest preset, test match, coverage settings)
- [ ] Create `backend/tests/setup.ts` (env mocks, Supabase mock, test helpers)

### 5B — Route Tests
- [ ] Create `backend/tests/users.test.ts` (happy path: get/update profile + error: unauthorized)
- [ ] Create `backend/tests/onboarding.test.ts` (happy path: save responses + error: invalid payload)
- [ ] Create `backend/tests/subscriptions.test.ts` (happy path: webhook processing + error: bad signature)
- [ ] Create `backend/tests/usage.test.ts` (happy path: check/log + error: limit reached)

### 5C — Middleware Tests
- [ ] Create `backend/tests/auth.test.ts` (valid token, missing token, expired token)
- [ ] Create `backend/tests/rateLimiter.test.ts` (under limit, at limit, over limit)

### 5D — CI/CD Pipelines
- [ ] Create `.github/workflows/ci.yml` (on PR: checkout, setup node 20, npm ci, lint, build, test)
- [ ] Create `.github/workflows/deploy.yml` (on main push: build Docker, deploy to Fly.io)
- [ ] Verify: `npm test` — all tests pass, `npm run lint` — zero errors

---

## Phase 6 — iOS App Foundation

Xcode project, design system, reusable components, core infrastructure.

### 6A — Project Setup
- [ ] Create Xcode project in `ios/` (SwiftUI App, iOS 17+, bundle ID placeholder)
- [ ] Add SPM packages: Supabase (v2.0.0+), RevenueCat (v4.0.0+), PostHog (v3.0.0+), GoogleSignIn (v7.0.0+)
- [ ] Configure `Info.plist` (URL schemes for Google Sign-In, push notification entitlement)
- [ ] Set up `Assets.xcassets` with named color sets (bg, bgElevated, bgSurface, textPrimary, textSecondary, textTertiary, accent, accentMuted, success, warning, danger, border, borderFocus)

### 6B — Design System Tokens
- [ ] Create `ios/Design/AppColors.swift` — Color extensions matching design system spec
- [ ] Create `ios/Design/AppFonts.swift` — display(), body(), mono() font helpers
- [ ] Create `ios/Design/AppSpacing.swift` — Spacing enum (xs=4 through xxxl=64) + Radius enum
- [ ] Create `ios/Design/AppTheme.swift` — AppTheme ObservableObject with @AppStorage color scheme
- [ ] Create `ios/Design/AppTransitions.swift` — slideUp, slidePush, fadeScale transitions

### 6C — Reusable Components
- [ ] Create `ios/Components/AppButton.swift` — primary, ghost, destructive variants + loading state + icon support
- [ ] Create `ios/Components/AppTextField.swift` — styled input with optional security/keyboard type
- [ ] Create `ios/Components/SkeletonView.swift` — shimmer loading placeholder (row + card variants)
- [ ] Create `ios/Components/EmptyStateView.swift` — illustration + title + subtitle + CTA action
- [ ] Create `ios/Components/AppDrawer.swift` — bottom sheet wrapper

### 6D — Core Layer
- [ ] Create `ios/Core/Network/APIClient.swift` — async/await HTTP client with auth token injection
- [ ] Create `ios/Core/Network/APIEndpoints.swift` — all endpoint URL definitions
- [ ] Create `ios/Core/Network/APIError.swift` — typed API error enum
- [ ] Create `ios/Core/Auth/AuthManager.swift` — Supabase auth session management
- [ ] Create `ios/Core/Auth/AppleSignInManager.swift` — Sign in with Apple flow
- [ ] Create `ios/Core/Auth/GoogleSignInManager.swift` — Google Sign-In flow
- [ ] Create `ios/Core/Storage/LocalDatabase.swift` — SwiftData model container setup
- [ ] Create `ios/Core/Storage/SyncManager.swift` — background sync coordinator (server-wins)
- [ ] Create `ios/Core/Analytics/Analytics.swift` — PostHog wrapper with typed AnalyticsEvent enum
- [ ] Create `ios/Core/Payments/PaymentManager.swift` — RevenueCat wrapper (configure, purchase, restore)
- [ ] Create `ios/Core/Notifications/NotificationManager.swift` — APNs registration + permission
- [ ] Create `ios/Core/Haptics/HapticManager.swift` — light, medium, heavy, success, error, selection

### 6E — Models
- [ ] Create `ios/Models/User.swift` — maps to profiles table
- [ ] Create `ios/Models/Subscription.swift` — maps to subscriptions table
- [ ] Create `ios/Models/OnboardingResponse.swift` — maps to onboarding_responses table

### 6F — App Entry & Environment
- [ ] Create `ios/App/AppEnvironment.swift` — shared environment objects (AuthManager, AppTheme, AppRouter)
- [ ] Create `ios/App/MyApp.swift` — @main entry point with environment injection + preferredColorScheme
- [ ] Verify: project builds (Cmd+B) with zero errors

---

## Phase 7 — iOS Screens & Navigation

All core screens per the ios/README.md wireframe specs.

### 7A — Splash
- [ ] Create `ios/Screens/Splash/SplashView.swift` — logo + app name centered, 2s delay, auto-advance based on auth state

### 7B — Auth
- [ ] Create `ios/Screens/Auth/LoginView.swift` — logo, tagline, Sign in with Apple button (HIG), Google Sign-In button, legal footer
- [ ] Create `ios/Screens/Auth/LoginViewModel.swift` — handles Apple + Google auth flows, error state

### 7C — Onboarding
- [ ] Create `ios/Screens/Onboarding/OnboardingView.swift` — step container with progress indicator + circular FAB next button
- [ ] Create `ios/Screens/Onboarding/OnboardingQuizStep.swift` — text input + multiple choice + info screen + notification setup step types
- [ ] Create `ios/Screens/Onboarding/OnboardingViewModel.swift` — step state, responses dict, advance logic, save to API

### 7D — Paywall
- [ ] Create `ios/Screens/Paywall/TrialExplainerView.swift` — timeline visualization, trust bullets, Start Free Trial CTA + ghost dismiss
- [ ] Create `ios/Screens/Paywall/PaywallView.swift` — feature list, yearly (highlighted) + monthly plan cards, purchase CTA, restore link, legal
- [ ] Create `ios/Screens/Paywall/PaywallViewModel.swift` — plan selection, RevenueCat purchase, loading/error state

### 7E — Home
- [ ] Create `ios/Screens/Home/HomeView.swift` — placeholder core feature screen (tab bar ready)
- [ ] Create `ios/Screens/Home/HomeViewModel.swift` — local-first data loading pattern

### 7F — Settings
- [ ] Create `ios/Screens/Settings/SettingsView.swift` — List with sections: Account, Preferences, Support, Legal + sign out
- [ ] Create `ios/Screens/Settings/SettingsViewModel.swift` — profile data, sign out, manage subscription

### 7G — Navigation
- [ ] Create `ios/App/AppRouter.swift` — @MainActor ObservableObject, RootDestination enum (splash/login/onboarding/paywall/home), advance logic
- [ ] Wire root view switch in `MyApp.swift` based on `AppRouter.root`
- [ ] Verify: full navigation flow compiles — splash → login → onboarding → paywall → home → settings

---

## Phase 8 — Integration, Polish & Deployment

End-to-end flows, analytics audit, deployment configuration.

### 8A — End-to-End Auth Flow
- [ ] Wire iOS Apple Sign-In → Supabase Auth → profile auto-creation trigger → API auth middleware
- [ ] Wire iOS Google Sign-In → Supabase Auth → same flow
- [ ] Test: sign in → onboarding → paywall → home → settings → sign out → back to login

### 8B — Local-First Sync
- [ ] Implement SyncManager pull: on app launch, fetch latest from API in background
- [ ] Implement SyncManager push: on local write, queue API sync with retry
- [ ] Implement conflict resolution: server-wins with last-write-wins timestamp comparison
- [ ] Test: write offline → come online → verify sync

### 8C — Analytics Audit
- [ ] Wire `Analytics.track(.login(method:))` on successful auth
- [ ] Wire `Analytics.track(.onboardingStarted)` and `.onboardingStepCompleted` in onboarding flow
- [ ] Wire `Analytics.track(.paywallViewed)`, `.planSelected`, `.trialStarted`, `.subscriptionPurchased` in paywall
- [ ] Wire `Analytics.track(.featureUsed)` on core home actions
- [ ] Server-side: wire `posthog.capture()` on subscription webhook events
- [ ] Verify: PostHog dashboard shows events for full user journey

### 8D — Push Notifications
- [ ] Configure APNs key in Apple Developer portal
- [ ] Register device token on app launch via NotificationManager
- [ ] Send token to `PUT /api/notifications/token`
- [ ] Test: receive a test push notification

### 8E — Deployment
- [ ] Deploy Supabase project to Supabase Cloud (create project, push migrations, set secrets)
- [ ] Deploy backend to Fly.io (`fly launch`, `fly secrets set`, `fly deploy`)
- [ ] Point iOS app config (AppEnvironment) to production Supabase URL + anon key + backend URL
- [ ] Configure RevenueCat webhook URL → production backend
- [ ] Configure PostHog project key for production

### 8F — App Store Prep
- [ ] Set production Bundle ID + Team ID
- [ ] Add App Icon (1024x1024) to Assets.xcassets
- [ ] Generate screenshots for App Store listing
- [ ] Archive build (Product → Archive) + upload to App Store Connect
- [ ] Verify: TestFlight build installs and full flow works on physical device

---

## Definition of Done (per task)

Every task above should satisfy:

- [ ] Code compiles (`xcodebuild` / `npm run build`)
- [ ] Lint passes (`npm run lint`)
- [ ] Tests pass (`npm test`) where applicable
- [ ] Analytics events fire for new user-facing actions
- [ ] RLS policies exist for any new database table
- [ ] `.env.example` updated if new env vars introduced
- [ ] No hardcoded secrets — use env vars or build config
