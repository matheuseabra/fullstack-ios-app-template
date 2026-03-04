# Rollout Plan

> Phased implementation of the AppStudio Boilerplate — from documented specs to production-ready code.
>
> **Current state:** Phase 5 complete — 35 tests passing, CI/CD pipelines configured.
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
- [x] Create migration `supabase/migrations/0001_shared_functions.sql`
  - `set_updated_at()` trigger function
  - `handle_new_user()` trigger function (auto-create profile on auth.users insert)

### 2B — Core Tables
- [x] Create migration `supabase/migrations/0002_profiles.sql`
  - Table: `profiles` (id, email, full_name, avatar_url, timezone, locale, created_at, updated_at)
  - RLS: select own, update own
  - Trigger: `on_auth_user_created` → `handle_new_user()`
  - Trigger: `set_updated_at`
- [x] Create migration `supabase/migrations/0003_onboarding_responses.sql`
  - Table: `onboarding_responses` (id, user_id, question_key, answer jsonb, created_at)
  - Index: `user_id`
  - RLS: all operations on own rows
- [x] Create migration `supabase/migrations/0004_subscriptions.sql`
  - Table: `subscriptions` (id, user_id, revenuecat_user_id, product_id, status, trial_ends_at, current_period_end, cancel_at_period_end, entitlements jsonb, created_at, updated_at)
  - Indexes: `user_id`, `revenuecat_user_id` (unique)
  - RLS: select own only (no insert/update/delete for users — service_role only)
  - Trigger: `set_updated_at`
- [x] Create migration `supabase/migrations/0005_notification_preferences.sql`
  - Table: `notification_preferences` (id, user_id, enabled, reminder_time, days_of_week, push_token, updated_at)
  - Unique index: `user_id`
  - RLS: all operations on own rows
  - Trigger: `set_updated_at`
- [x] Create migration `supabase/migrations/0006_user_settings.sql`
  - Table: `user_settings` (user_id, key, value jsonb, updated_at) — composite PK
  - RLS: all operations on own rows
- [x] Create migration `supabase/migrations/0007_usage_logs.sql`
  - Table: `usage_logs` (id, user_id, feature, count, metadata jsonb, created_at)
  - Index: `(user_id, feature, created_at)`
  - RLS: select own only (service_role inserts)
- [x] Create migration `supabase/migrations/0008_api_rate_limits.sql`
  - Table: `api_rate_limits` (user_id, endpoint, count, window_start) — composite PK
  - No RLS (service_role only)
- [x] Create migration `supabase/migrations/0009_audit_log.sql`
  - Table: `audit_log` (id bigint identity, user_id, action, metadata jsonb, ip_address inet, user_agent, created_at)
  - Indexes: `user_id`, `created_at`
  - No user RLS (service_role only)

### 2C — Seed & Types
- [x] Create `supabase/seed.sql` with test user profile + sample data
- [x] Verify: run all migrations in Supabase Studio SQL editor
- [x] Run `supabase gen types typescript --local > backend/src/types/database.ts`

---

## Phase 3 — Backend Core

App entry point, middleware stack, service clients, shared libraries.

### 3A — Shared Libs
- [x] Create `backend/src/lib/errors.ts` — AppError class with code, status, message
- [x] Create `backend/src/lib/response.ts` — success/error JSON response helpers
- [x] Create `backend/src/lib/logger.ts` — Pino logger setup

### 3B — Type Definitions
- [x] Create `backend/src/types/index.ts` — shared TypeScript types (User, Subscription, etc.)
- [x] Create `backend/src/types/env.ts` — Zod schema for env vars with typed parse

### 3C — Service Clients
- [x] Create `backend/src/services/supabase.ts` — anon client + service_role client
- [x] Create `backend/src/services/redis.ts` — Redis client (optional, graceful fallback)
- [x] Create `backend/src/services/revenuecat.ts` — webhook signature validator + API client
- [x] Create `backend/src/services/posthog.ts` — server-side event tracking client
- [x] Create `backend/src/services/r2.ts` — Cloudflare R2 storage client (opt-in)

### 3D — Middleware
- [x] Create `backend/src/middleware/auth.ts` — JWT verification via Supabase `getUser()`
- [x] Create `backend/src/middleware/rateLimiter.ts` — sliding window (Redis primary, in-memory fallback)
- [x] Create `backend/src/middleware/usageCap.ts` — per-user feature limits based on subscription tier
- [x] Create `backend/src/middleware/requestLogger.ts` — structured request/response logging
- [x] Create `backend/src/middleware/errorHandler.ts` — centralized error → JSON response mapping

### 3E — App Bootstrap
- [x] Create `backend/src/app.ts` — Hono app with global middleware (CORS, logger, secureHeaders), OpenAPI/Swagger (dev), health check, route mounting, error handler
- [x] Create `backend/src/index.ts` — entry point (env parse, app import, `serve()` on PORT)
- [x] Verify: `npm run dev` starts server, `GET /health` returns `{ status: "ok" }`

---

## Phase 4 — Backend API Routes

All endpoints with Zod validation, per the backend/README.md spec.

### 4A — Schemas
- [x] Create `backend/src/schemas/user.schema.ts` — profile update, settings CRUD
- [x] Create `backend/src/schemas/onboarding.schema.ts` — quiz response submission
- [x] Create `backend/src/schemas/subscription.schema.ts` — RevenueCat webhook payload
- [x] Create `backend/src/schemas/usage.schema.ts` — usage check/log
- [x] Create `backend/src/schemas/notification.schema.ts` — push token + preferences

### 4B — Route Handlers
- [x] Create `backend/src/routes/auth.ts` — public webhook/callback handlers
- [x] Create `backend/src/routes/users.ts`
  - `GET /api/users/me` — get own profile
  - `PUT /api/users/me` — update profile
  - `GET /api/users/me/settings` — get settings
  - `PUT /api/users/me/settings` — upsert setting by key
- [x] Create `backend/src/routes/onboarding.ts`
  - `POST /api/onboarding/responses` — save quiz answers (batch)
- [x] Create `backend/src/routes/subscriptions.ts`
  - `POST /auth/webhook/revenuecat` — RevenueCat webhook (signature-verified, service_role write)
  - `GET /api/subscriptions/me` — get own subscription status
- [x] Create `backend/src/routes/usage.ts`
  - `GET /api/usage/:feature` — check remaining usage for feature
  - `POST /api/usage/:feature` — log usage event
- [x] Create `backend/src/routes/notifications.ts`
  - `PUT /api/notifications/token` — register/update APNs push token
  - `GET /api/notifications/preferences` — get notification prefs
  - `PUT /api/notifications/preferences` — update notification prefs

### 4C — Route Mounting & Verification
- [x] Mount all routes in `app.ts` (public: `/auth/*`, protected: `/api/*`)
- [x] Apply `authMiddleware` + `rateLimiter` to `/api/*`
- [x] Verify: all routes respond correctly with mock/manual testing
- [x] Run `npm run lint` — zero errors

---

## Phase 5 — Backend Testing & CI/CD

Jest test suite + GitHub Actions pipelines.

### 5A — Test Setup
- [x] Create `backend/jest.config.ts` (ts-jest preset, test match, coverage settings)
- [x] Create `backend/tests/setup.ts` (env mocks, Supabase mock, test helpers)

### 5B — Route Tests
- [x] Create `backend/tests/users.test.ts` (happy path: get/update profile + error: unauthorized)
- [x] Create `backend/tests/onboarding.test.ts` (happy path: save responses + error: invalid payload)
- [x] Create `backend/tests/subscriptions.test.ts` (happy path: webhook processing + error: bad signature)
- [x] Create `backend/tests/usage.test.ts` (happy path: check/log + error: limit reached)

### 5C — Middleware Tests
- [x] Create `backend/tests/auth.test.ts` (valid token, missing token, expired token)
- [x] Create `backend/tests/rateLimiter.test.ts` (under limit, at limit, over limit)

### 5D — CI/CD Pipelines
- [x] Create `.github/workflows/ci.yml` (on PR: checkout, setup node 20, npm ci, lint, build, test)
- [x] Create `.github/workflows/deploy.yml` (on main push: build Docker, deploy to Fly.io)
- [x] Verify: `npm test` — all tests pass, `npm run lint` — zero errors

---

## Phase 6 — iOS App Foundation

Xcode project, design system, reusable components, core infrastructure.

### 6A — Project Setup
- [x] Create Xcode project in `ios/` (SwiftUI App, iOS 17+, bundle ID placeholder)
- [x] Add SPM packages: Supabase (v2.0.0+), RevenueCat (v4.0.0+), PostHog (v3.0.0+), GoogleSignIn (v7.0.0+)
- [ ] Configure `Info.plist` (URL schemes for Google Sign-In, push notification entitlement)
- [x] Set up `Assets.xcassets` with named color sets (bg, bgElevated, bgSurface, textPrimary, textSecondary, textTertiary, accent, accentMuted, success, warning, danger, border, borderFocus)

### 6B — Design System Tokens
- [x] Create `ios/Design/AppColors.swift` — Color extensions matching design system spec
- [x] Create `ios/Design/AppFonts.swift` — display(), body(), mono() font helpers
- [x] Create `ios/Design/AppSpacing.swift` — Spacing enum (xs=4 through xxxl=64) + Radius enum
- [x] Create `ios/Design/AppTheme.swift` — AppTheme ObservableObject with @AppStorage color scheme
- [x] Create `ios/Design/AppTransitions.swift` — slideUp, slidePush, fadeScale transitions

### 6C — Reusable Components
- [x] Create `ios/Components/AppButton.swift` — primary, ghost, destructive variants + loading state + icon support
- [x] Create `ios/Components/AppTextField.swift` — styled input with optional security/keyboard type
- [x] Create `ios/Components/SkeletonView.swift` — shimmer loading placeholder (row + card variants)
- [x] Create `ios/Components/EmptyStateView.swift` — illustration + title + subtitle + CTA action
- [x] Create `ios/Components/AppDrawer.swift` — bottom sheet wrapper

### 6D — Core Layer
- [x] Create `ios/Core/Network/APIClient.swift` — async/await HTTP client with auth token injection
- [x] Create `ios/Core/Network/APIEndpoints.swift` — all endpoint URL definitions
- [x] Create `ios/Core/Network/APIError.swift` — typed API error enum
- [x] Create `ios/Core/Auth/AuthManager.swift` — Supabase auth session management
- [x] Create `ios/Core/Auth/AppleSignInManager.swift` — Sign in with Apple flow
- [x] Create `ios/Core/Auth/GoogleSignInManager.swift` — Google Sign-In flow
- [x] Create `ios/Core/Storage/LocalDatabase.swift` — SwiftData model container setup
- [x] Create `ios/Core/Storage/SyncManager.swift` — background sync coordinator (server-wins)
- [x] Create `ios/Core/Analytics/Analytics.swift` — PostHog wrapper with typed AnalyticsEvent enum
- [x] Create `ios/Core/Payments/PaymentManager.swift` — RevenueCat wrapper (configure, purchase, restore)
- [x] Create `ios/Core/Notifications/NotificationManager.swift` — APNs registration + permission
- [x] Create `ios/Core/Haptics/HapticManager.swift` — light, medium, heavy, success, error, selection

### 6E — Models
- [x] Create `ios/Models/User.swift` — maps to profiles table
- [x] Create `ios/Models/Subscription.swift` — maps to subscriptions table
- [x] Create `ios/Models/OnboardingResponse.swift` — maps to onboarding_responses table

### 6F — App Entry & Environment
- [x] Create `ios/App/AppEnvironment.swift` — shared environment objects (AuthManager, AppTheme, AppRouter)
- [x] Create `ios/App/MyApp.swift` (AppTemplateApp.swift) — @main entry point with environment injection + preferredColorScheme
- [x] Verify: project builds (Cmd+B) with zero errors

---

## Phase 7 — iOS Screens & Navigation

All core screens per the ios/README.md wireframe specs.

### 7A — Splash
- [x] Create `ios/Screens/Splash/SplashView.swift` (stub) — logo + app name centered, 2s delay, auto-advance based on auth state

### 7B — Auth
- [x] Create `ios/Screens/Auth/LoginView.swift` (stub) — logo, tagline, Sign in with Apple button (HIG), Google Sign-In button, legal footer
- [x] Create `ios/Screens/Auth/LoginViewModel.swift` — handles Apple + Google auth flows, error state

### 7C — Onboarding
- [x] Create `ios/Screens/Onboarding/OnboardingView.swift` (stub) — step container with progress indicator + circular FAB next button
- [x] Create `ios/Screens/Onboarding/OnboardingQuizStep.swift` — text input + multiple choice + info screen + notification setup step types
- [x] Create `ios/Screens/Onboarding/OnboardingViewModel.swift` — step state, responses dict, advance logic, save to API

### 7D — Paywall
- [x] Create `ios/Screens/Paywall/TrialExplainerView.swift` (stub) — timeline visualization, trust bullets, Start Free Trial CTA + ghost dismiss
- [x] Create `ios/Screens/Paywall/PaywallView.swift` — feature list, yearly (highlighted) + monthly plan cards, purchase CTA, restore link, legal
- [x] Create `ios/Screens/Paywall/PaywallViewModel.swift` — plan selection, RevenueCat purchase, loading/error state

### 7E — Home
- [x] Create `ios/Screens/Home/HomeView.swift` (stub) — placeholder core feature screen (tab bar ready)
- [x] Create `ios/Screens/Home/HomeViewModel.swift` — local-first data loading pattern

### 7F — Settings
- [x] Create `ios/Screens/Settings/SettingsView.swift` (stub) — List with sections: Account, Preferences, Support, Legal + sign out
- [x] Create `ios/Screens/Settings/SettingsViewModel.swift` — profile data, sign out, manage subscription

### 7G — Navigation
- [x] Create `ios/App/AppRouter.swift` — @MainActor ObservableObject, RootDestination enum (splash/login/onboarding/paywall/home), advance logic
- [x] Wire root view switch in `MyApp.swift` based on `AppRouter.root`
- [x] Verify: full navigation flow compiles — splash → login → onboarding → paywall → home → settings

---

## Phase 8 — Integration, Polish & Deployment

End-to-end flows, analytics audit, deployment configuration.

### 8A — End-to-End Auth Flow
- [x] Wire iOS Apple Sign-In → Supabase Auth → profile auto-creation trigger → API auth middleware
- [x] Wire iOS Google Sign-In → Supabase Auth → same flow
- [ ] Test: sign in → onboarding → paywall → home → settings → sign out → back to login

### 8B — Local-First Sync
- [x] Implement SyncManager pull: on app launch, fetch latest from API in background
- [x] Implement SyncManager push: on local write, queue API sync with retry
- [x] Implement conflict resolution: server-wins with last-write-wins timestamp comparison
- [ ] Test: write offline → come online → verify sync

### 8C — Analytics Audit
- [x] Wire `Analytics.track(.login(method:))` on successful auth
- [ ] Wire `Analytics.track(.onboardingStarted)` and `.onboardingStepCompleted` in onboarding flow
- [x] Wire `Analytics.track(.paywallViewed)`, `.planSelected`, `.trialStarted`, `.subscriptionPurchased` in paywall
- [x] Wire `Analytics.track(.featureUsed)` on core home actions
- [x] Server-side: wire `posthog.capture()` on subscription webhook events
- [ ] Verify: PostHog dashboard shows events for full user journey

### 8D — Push Notifications
- [ ] Configure APNs key in Apple Developer portal
- [x] Register device token on app launch via NotificationManager
- [x] Send token to `PUT /api/notifications/token`
- [ ] Test: receive a test push notification

### 8E — Deployment
- [ ] Deploy Supabase project to Supabase Cloud (create project, push migrations, set secrets)
- [ ] Deploy backend to Fly.io (`fly launch`, `fly secrets set`, `fly deploy`)
- [x] Point iOS app config (AppEnvironment) to production Supabase URL + anon key + backend URL
- [ ] Configure RevenueCat webhook URL → production backend
- [ ] Configure PostHog project key for production

### 8F — App Store Prep
- [ ] Set production Bundle ID + Team ID
- [ ] Add App Icon (1024x1024) to Assets.xcassets
- [ ] Generate screenshots for App Store listing
- [ ] Archive build (Product → Archive) + upload to App Store Connect
- [ ] Verify: TestFlight build installs and full flow works on physical device

---

## Phase 9 — Task Manager Feature

Replaces the placeholder `HomeView` with a full task manager — local-first with Supabase sync.

### 9A — Data Model
- [x] Create `ios/Models/TaskItem.swift` — SwiftData `@Model` with `id`, `title`, `note`, `isCompleted`, `priority`, `dueDate`, `completedAt`, `syncStatus`, `supabaseId`
- [x] Add `Priority` enum (`low` / `medium` / `high`) + `SyncStatus` enum (`synced` / `pendingUpload` / `pendingUpdate` / `pendingDelete`)
- [x] Add `TaskDTO`, `TaskResponse`, `TaskListResponse` Codable structs for API transport
- [x] Register `TaskItem.self` in `LocalDatabase.swift` Schema array
- [x] Delete unused Xcode boilerplate `Item.swift` and `ContentView.swift`

### 9B — Backend
- [x] Create `supabase/migrations/0010_tasks.sql` — `tasks` table with RLS (select/insert/update/delete own rows) + indexes on `(user_id, due_date)` and `(user_id, is_completed)` + `set_updated_at` trigger
- [x] Add `tasks` table type to `backend/src/types/database.ts`
- [x] Create `backend/src/schemas/task.schema.ts` — `createTaskSchema` + `updateTaskSchema` (Zod)
- [x] Create `backend/src/routes/tasks.ts` — `GET /api/tasks`, `GET /api/tasks/:id`, `POST /api/tasks`, `PUT /api/tasks/:id`, `DELETE /api/tasks/:id`
- [x] Mount `/api/tasks` in `backend/src/app.ts`
- [x] Add `delete<T>()` method to `APIClient.swift`
- [x] Add task endpoints to `APIEndpoints.swift` (`tasks`, `task(_ id:)`)
- [x] Apply migration via `supabase db reset` (local dev) — use `supabase db push` in staging/production

### 9C — iOS Views
- [x] Create `Screens/Tasks/TasksTabView.swift` — root container with custom 3-zone tab bar (Dashboard | FAB center | Tasks)
- [x] Create `Screens/Tasks/DashboardView.swift` — greeting, week calendar strip, summary card, daily tasks list
- [x] Create `Screens/Tasks/WeekCalendarStrip.swift` — horizontal scrollable day pills with today indicator dot
- [x] Create `Screens/Tasks/TaskSummaryCard.swift` — circular progress ring + completion stats
- [x] Create `Screens/Tasks/TaskDetailCard.swift` — task row with checkbox, priority badge, due time, overdue highlight
- [x] Create `Screens/Tasks/TaskListView.swift` — searchable list with segmented filter (All/Pending/Completed) + swipe-to-delete + swipe-to-complete
- [x] Create `Screens/Tasks/AddTaskView.swift` — bottom sheet drawer with title, note, priority chips, optional date picker
- [x] Create `Screens/Tasks/TasksViewModel.swift` — SwiftData CRUD, server sync, derived data (greeting, completionRate, todayTasks)

### 9D — Sync Layer
- [x] Implement `SyncManager.pull()` — fetches all tasks from `GET /api/tasks`, merges into local SwiftData (server-wins when `syncStatus == .synced`)
- [x] ViewModel push methods: `pushTask()`, `updateTaskOnServer()`, `deleteTaskOnServer()` (guarded behind `#if !DEBUG`)
- [x] Offline safety: local mutations persist immediately; sync failures are logged, not thrown

### 9E — Routing
- [x] `AppTemplateApp.swift`: `case .home: TasksTabView()` (was `HomeView()`)
- [x] Settings gear in `DashboardView` opens `SettingsView` sheet (consistent with old `HomeView`)

### 9F — Analytics & Haptics
- [x] `Analytics.track(.featureUsed("task_created"))` on add
- [x] `Analytics.track(.featureUsed("task_completed"))` on toggle
- [x] `Analytics.track(.featureUsed("task_deleted"))` on delete
- [x] `HapticManager.success()` on task creation
- [x] `HapticManager.light()` on toggle, `HapticManager.medium()` on delete
- [x] `HapticManager.selection()` on tab switch, calendar day selection, priority chip selection

### 9G — Verification
- [x] iOS build succeeds: `xcodebuild -scheme AppTemplate` for simulator
- [x] Backend types check clean: `npx tsc --noEmit` (zero errors)
- [x] Migration applied: `supabase db reset` confirms `0010_tasks.sql` applied

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
