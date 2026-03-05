# Architecture Decisions

> Why we made the choices we made. Read before proposing alternatives.

Related guide: [Environments (Dev + Prod)](./ENVIRONMENTS.md)

---

## ADR-001: Hono over Express/Fastify

**Decision:** Hono for the API layer.

**Why:**
- Tiny bundle (~14kb), near-zero overhead
- First-class TypeScript, Zod, and OpenAPI support via `@hono/zod-validator`
- Edge-ready (Fly.io, Cloudflare Workers, Lambda) with zero config changes
- Middleware is just functions — easy to test in isolation

**Trade-off:** Smaller ecosystem than Express. Acceptable because we use Supabase for heavy lifting.

---

## ADR-002: Supabase over custom Postgres

**Decision:** Supabase for database, auth, and realtime.

**Why:**
- Auth (social login + JWT) out of the box — removes weeks of work
- RLS means the DB enforces access control even if backend has bugs
- Local dev stack via `supabase start` — identical schema between dev + prod
- Generous free tier (500MB DB, 50k MAU auth) covers early-stage apps
- `supabase gen types` keeps TypeScript types in sync automatically

**Trade-off:** Supabase-specific APIs. Migration to raw Postgres requires effort. Acceptable — we're optimizing for ship speed.

---

## ADR-003: RevenueCat over StoreKit directly

**Decision:** RevenueCat SDK for payments.

**Why:**
- Handles StoreKit 2 complexity, receipt validation, server notifications
- Webhook → backend subscription sync is well-documented
- Free up to $2.5k MRR — covers most early apps entirely
- Dashboard gives LTV, churn, and cohort data with zero setup

**Trade-off:** Third-party dependency for critical path. RevenueCat has 99.9% uptime SLA and is the industry standard.

---

## ADR-004: Local-first with background sync

**Decision:** SwiftData for local storage, background sync to Supabase.

**Why:**
- App feels instant — no loading spinner on core screens
- Works offline — a health/productivity app that breaks without signal is a bad UX
- Reduces API calls — better for rate limits and Supabase free tier
- SwiftData (iOS 17+) integrates natively with SwiftUI

**Pattern:**
1. On app launch: load from SwiftData immediately
2. In background: fetch from API + merge (server wins on conflict)
3. On user write: write to SwiftData first (optimistic), queue API sync
4. If sync fails: retry with exponential backoff, show subtle error state

---

## ADR-005: No email/password auth

**Decision:** Social login only (Apple + Google).

**Why:**
- Removes friction — no "forgot password" flow, no email verification
- Apple Sign In is required by App Store guidelines when any social login is offered
- Reduces support load — no locked accounts
- Users trust Apple/Google with their credentials more than your startup

**Trade-off:** Some users won't have Google/Apple accounts. Tiny minority on iOS.

---

## ADR-006: Fly.io over AWS/GCP

**Decision:** Fly.io for API hosting.

**Why:**
- Free hobby tier: 3 shared VMs, 160GB bandwidth/month
- Global edge deployment with one command: `fly deploy`
- Auto-stop machines = zero cost when unused (perfect for multiple apps)
- No VPC/IAM/subnet configuration — just code and ship

**Trade-off:** Less control than EC2. Fine — we don't need it.

---

## ADR-007: Monorepo (iOS + Backend)

**Decision:** iOS app and backend in the same repo.

**Why:**
- Atomic commits: "add paywall" touches iOS view + API route + DB migration together
- Agents have full context without switching repos
- Shared type definitions via OpenAPI codegen (future)
- One CI pipeline, one PR review

**Trade-off:** Slightly larger clone. Irrelevant for a studio of 1-3 people.

---

## ADR-008: PostHog over Mixpanel/Amplitude

**Decision:** PostHog for product analytics.

**Why:**
- Open source — self-hostable if you outgrow the free tier (1M events/month)
- Session recording, feature flags, A/B tests all in one SDK
- iOS SDK + server SDK = unified user journey tracking
- Free tier covers most apps through early growth stage

---

## Usage Cap Approach

Usage caps (e.g., "free users get 5 AI generations/day") are enforced at the API layer via `usageCap` middleware, not in the iOS app.

**Why at the API, not iOS:**
- iOS apps can be reverse-engineered / modified
- Backend is the source of truth for entitlements
- Consistent enforcement across web, iOS, future Android

**Cap tiers defined per route:**
```typescript
usageCap({ feature: 'ai_chat', freeTierLimit: 5, paidTierLimit: 'unlimited' })
```

Counts stored in `usage_logs` table, indexed by `(user_id, feature, created_at)` for fast daily aggregation.

---

## ADR-009: Plug-and-Play Feature Flags

**Decision:** Boolean feature flags at both the iOS and backend layers to enable/disable entire features without touching UI code or rewriting navigation.

**Why:**
- Template apps don't always need every feature (auth, onboarding, paywall, notifications)
- Developers should flip a flag and rebuild — no code surgery
- Disabled features are cleanly skipped at every layer: navigation, service init, UI, API routes

### iOS Feature Flags (`Env` file / `AppEnvironment.swift`)

| Flag | Default | Controls |
|------|---------|----------|
| `ENABLE_AUTH` | `true` | Login screen, backend sync, JWT. When `false` the app runs local-only. |
| `ENABLE_ONBOARDING` | `true` | Onboarding quiz flow after first sign-in. |
| `ENABLE_PAYWALL` | `true` | Subscription gate before Home. RevenueCat initialization. |
| `ENABLE_NOTIFICATIONS` | `true` | APNs registration, notification setup in onboarding, Settings section. |
| `ENABLE_ANALYTICS` | `true` | PostHog SDK initialization and event tracking. |
| `ENABLE_APPLE_SIGN_IN` | `false` | Apple Sign In button (sub-flag of auth). |
| `ENABLE_GOOGLE_SIGN_IN` | `true` | Google Sign In button (sub-flag of auth). |

**Navigation flow adapts automatically:**
```
Splash → [Auth?] → [Onboarding?] → [Paywall?] → Home
```
Each gate is skipped when its flag is `false`. Setting auth + onboarding + paywall to `false` sends users straight from splash to Home (MVP/prototype mode).

**Service initialization is conditional:**
- `PaymentManager.configure()` only runs when `ENABLE_PAYWALL=true`
- `Analytics.configure()` only runs when `ENABLE_ANALYTICS=true`
- `SyncManager.pullIfNeeded()` only runs when `ENABLE_AUTH=true`
- `GoogleSignInManager.configure()` only runs when both auth and Google sign-in are enabled

### Backend Feature Flags (environment variables / `.env`)

| Flag | Default | Controls |
|------|---------|----------|
| `ENABLE_ONBOARDING` | `true` | `/api/onboarding` routes |
| `ENABLE_SUBSCRIPTIONS` | `true` | `/api/subscriptions` routes |
| `ENABLE_NOTIFICATIONS` | `true` | `/api/notifications` routes |
| `ENABLE_USAGE_TRACKING` | `true` | `/api/usage` routes |

Always-on routes: `/auth` (webhooks), `/api/users`, `/api/tasks`, `/health`.

Disabled routes are simply not mounted — requests return 404.

### Database Migrations

All migrations always run (Supabase requires sequential execution). Each migration file is tagged with its feature:
- **CORE:** 0001 (shared functions), 0002 (profiles), 0006 (user_settings), 0008 (api_rate_limits), 0009 (audit_log)
- **ONBOARDING:** 0003 (onboarding_responses)
- **SUBSCRIPTIONS:** 0004 (subscriptions)
- **NOTIFICATIONS:** 0005 (notification_preferences)
- **USAGE TRACKING:** 0007 (usage_logs)
- **TASKS:** 0010 (tasks)

Unused tables remain empty — zero performance overhead.

### Presets

| Preset | Auth | Onboarding | Paywall | Notifications | Analytics |
|--------|------|-----------|---------|---------------|-----------|
| **Full app** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Freemium** | ✅ | ✅ | ❌ | ✅ | ✅ |
| **MVP / prototype** | ❌ | ❌ | ❌ | ❌ | ❌ |
