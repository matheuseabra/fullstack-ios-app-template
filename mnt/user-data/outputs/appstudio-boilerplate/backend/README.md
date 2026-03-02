# Backend — Setup & Architecture

> Hono API on Node.js + TypeScript. Runs locally with Docker, deploys to Fly.io.

---

## Prerequisites

- Node.js 20+
- Docker + Docker Compose
- Supabase CLI

---

## Folder Structure

```
backend/
├── src/
│   ├── index.ts                    # Entry point, app bootstrap
│   ├── app.ts                      # Hono app, middleware chain, route mount
│   │
│   ├── routes/
│   │   ├── auth.ts                 # /auth/* — webhook handlers
│   │   ├── users.ts                # /users/* — profile, settings
│   │   ├── onboarding.ts           # /onboarding/* — save quiz responses
│   │   ├── subscriptions.ts        # /subscriptions/* — RevenueCat webhooks
│   │   ├── usage.ts                # /usage/* — cap checks, log usage
│   │   ├── notifications.ts        # /notifications/* — push token, prefs
│   │   └── [feature].ts            # App-specific routes go here
│   │
│   ├── middleware/
│   │   ├── auth.ts                 # JWT verify via Supabase
│   │   ├── rateLimiter.ts          # Sliding window rate limit (Redis or in-mem)
│   │   ├── usageCap.ts             # Per-user feature usage enforcement
│   │   ├── requestLogger.ts        # Structured request logging
│   │   └── errorHandler.ts         # Centralized error → response mapping
│   │
│   ├── services/
│   │   ├── supabase.ts             # Supabase client (anon + service role)
│   │   ├── redis.ts                # Redis client (opt-in)
│   │   ├── revenuecat.ts           # RevenueCat webhook validator + API
│   │   ├── posthog.ts              # PostHog server-side events
│   │   └── r2.ts                   # Cloudflare R2 client (opt-in)
│   │
│   ├── schemas/
│   │   ├── user.schema.ts          # Zod schemas for user routes
│   │   ├── onboarding.schema.ts
│   │   ├── subscription.schema.ts
│   │   └── [feature].schema.ts
│   │
│   ├── types/
│   │   ├── index.ts                # Shared TypeScript types
│   │   └── env.ts                  # Typed env vars (via Zod parse)
│   │
│   └── lib/
│       ├── errors.ts               # AppError class + error codes
│       ├── response.ts             # Consistent JSON response helpers
│       └── logger.ts               # Pino logger setup
│
├── supabase/                       # Supabase local config + migrations
│   ├── config.toml
│   ├── migrations/
│   │   ├── 0001_core_tables.sql    # profiles, subscriptions, etc.
│   │   ├── 0002_rls_policies.sql
│   │   └── 0003_triggers.sql
│   └── seed.sql                    # Dev seed data
│
├── tests/
│   ├── setup.ts
│   ├── auth.test.ts
│   ├── users.test.ts
│   ├── subscriptions.test.ts
│   └── usage.test.ts
│
├── .github/
│   └── workflows/
│       ├── ci.yml                  # Test + lint on PR
│       └── deploy.yml              # Deploy to Fly.io on main push
│
├── .env.example
├── .env                            # gitignored
├── .eslintrc.json
├── .prettierrc
├── Dockerfile
├── docker-compose.yml              # Local: Supabase + Redis + API
├── docker-compose.prod.yml         # Prod: API only (Supabase cloud)
├── fly.toml                        # Fly.io deploy config
├── jest.config.ts
├── tsconfig.json
├── package.json
└── README.md                       # This file
```

---

## Key Files

### `src/app.ts`

```typescript
import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'
import { secureHeaders } from 'hono/secure-headers'
import { prettyJSON } from 'hono/pretty-json'
import { swaggerUI } from '@hono/swagger-ui'
import { openAPISpecs } from 'hono-openapi'

import { authMiddleware } from './middleware/auth'
import { rateLimiter } from './middleware/rateLimiter'
import { errorHandler } from './middleware/errorHandler'

import authRoutes from './routes/auth'
import userRoutes from './routes/users'
import onboardingRoutes from './routes/onboarding'
import subscriptionRoutes from './routes/subscriptions'
import usageRoutes from './routes/usage'

const app = new Hono()

// Global middleware
app.use('*', cors({ origin: process.env.ALLOWED_ORIGINS?.split(',') ?? '*' }))
app.use('*', logger())
app.use('*', secureHeaders())

// OpenAPI docs (dev only)
if (process.env.NODE_ENV !== 'production') {
  app.get('/docs', swaggerUI({ url: '/openapi' }))
  app.get('/openapi', openAPISpecs(app))
}

// Health check
app.get('/health', (c) => c.json({ status: 'ok', ts: Date.now() }))

// Public routes
app.route('/auth', authRoutes)

// Protected routes — auth required
app.use('/api/*', authMiddleware)
app.use('/api/*', rateLimiter({ requests: 100, window: '1m' }))
app.route('/api/users', userRoutes)
app.route('/api/onboarding', onboardingRoutes)
app.route('/api/subscriptions', subscriptionRoutes)
app.route('/api/usage', usageRoutes)

// Error handler (must be last)
app.onError(errorHandler)

export default app
```

---

### `src/middleware/auth.ts`

```typescript
import { createMiddleware } from 'hono/factory'
import { supabaseService } from '../services/supabase'
import { AppError } from '../lib/errors'

export const authMiddleware = createMiddleware(async (c, next) => {
  const token = c.req.header('Authorization')?.replace('Bearer ', '')

  if (!token) throw new AppError(401, 'UNAUTHORIZED', 'Missing auth token')

  const { data: { user }, error } = await supabaseService.auth.getUser(token)

  if (error || !user) throw new AppError(401, 'UNAUTHORIZED', 'Invalid token')

  c.set('user', user)
  c.set('userId', user.id)
  await next()
})
```

---

### `src/middleware/rateLimiter.ts`

```typescript
// Sliding window rate limiter
// Uses Redis if available, falls back to in-memory Map

interface RateLimitOptions {
  requests: number     // max requests
  window: string       // '1m', '1h', '1d'
}

export const rateLimiter = (opts: RateLimitOptions) =>
  createMiddleware(async (c, next) => {
    const userId = c.get('userId') ?? c.req.header('x-forwarded-for') ?? 'anon'
    const key = `ratelimit:${userId}:${c.req.path}`

    // Check + increment
    const count = await redis.incr(key)
    if (count === 1) await redis.expire(key, parseWindowToSeconds(opts.window))

    c.header('X-RateLimit-Limit', String(opts.requests))
    c.header('X-RateLimit-Remaining', String(Math.max(0, opts.requests - count)))

    if (count > opts.requests) {
      throw new AppError(429, 'RATE_LIMITED', 'Too many requests')
    }

    await next()
  })
```

---

### `src/middleware/usageCap.ts`

```typescript
// Enforce per-user feature usage limits based on subscription tier
// Free tier: limited; Paid: higher or unlimited

interface UsageCapOptions {
  feature: string
  freeTierLimit: number
  paidTierLimit: number | 'unlimited'
}

export const usageCap = (opts: UsageCapOptions) =>
  createMiddleware(async (c, next) => {
    const userId = c.get('userId')

    // Get subscription status
    const { data: sub } = await supabaseService
      .from('subscriptions')
      .select('status, entitlements')
      .eq('user_id', userId)
      .single()

    const isPaid = ['trial', 'active'].includes(sub?.status ?? '')
    const limit = isPaid ? opts.paidTierLimit : opts.freeTierLimit

    if (limit !== 'unlimited') {
      // Count today's usage
      const { count } = await supabaseService
        .from('usage_logs')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('feature', opts.feature)
        .gte('created_at', new Date().toISOString().split('T')[0])

      if ((count ?? 0) >= limit) {
        throw new AppError(403, 'USAGE_LIMIT_REACHED', `Daily limit reached for ${opts.feature}`)
      }
    }

    await next()
  })
```

---

### `src/routes/subscriptions.ts`

```typescript
// RevenueCat webhook endpoint
// IMPORTANT: This is service_role only — never expose user JWT here

app.post('/webhook/revenuecat', async (c) => {
  const signature = c.req.header('X-RevenueCat-Signature')
  const body = await c.req.text()

  // Validate webhook signature
  if (!validateRevenueCatSignature(body, signature)) {
    return c.json({ error: 'Invalid signature' }, 401)
  }

  const event = JSON.parse(body)

  switch (event.type) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
    case 'PRODUCT_CHANGE':
      await upsertSubscription(event, 'active')
      break
    case 'TRIAL_STARTED':
      await upsertSubscription(event, 'trial')
      break
    case 'EXPIRATION':
    case 'CANCELLATION':
      await upsertSubscription(event, 'expired')
      break
  }

  return c.json({ received: true })
})
```

---

## Environment Variables

```bash
# .env.example

# Server
NODE_ENV=development
PORT=3000
ALLOWED_ORIGINS=http://localhost:3000

# Supabase
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# RevenueCat
REVENUECAT_WEBHOOK_SECRET=your_webhook_secret
REVENUECAT_API_KEY=your_api_key

# PostHog
POSTHOG_API_KEY=phc_xxxxx
POSTHOG_HOST=https://app.posthog.com  # or self-hosted

# Redis (opt-in)
REDIS_URL=redis://localhost:6379

# Cloudflare R2 (opt-in)
R2_ACCOUNT_ID=
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET_NAME=
```

---

## Scripts

```json
{
  "scripts": {
    "dev": "nodemon --exec tsx src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "jest",
    "test:watch": "jest --watch",
    "lint": "eslint src/",
    "format": "prettier --write src/",
    "db:start": "supabase start",
    "db:stop": "supabase stop",
    "db:push": "supabase db push",
    "db:reset": "supabase db reset",
    "db:types": "supabase gen types typescript --local > src/types/database.ts"
  }
}
```

---

## Docker

```yaml
# docker-compose.yml (local dev)
services:
  api:
    build: .
    ports: ["3000:3000"]
    environment:
      - NODE_ENV=development
    env_file: .env
    volumes:
      - ./src:/app/src     # hot reload
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]

  # Supabase runs via CLI (supabase start)
  # not in docker-compose to use official tooling
```

```dockerfile
# Dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

---

## Deploy to Fly.io

```bash
# First time
fly launch
fly secrets set SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... # etc.

# Deploy
fly deploy
```

```toml
# fly.toml
app = "your-app-api"
primary_region = "iad"

[build]
  dockerfile = "Dockerfile"

[http_service]
  internal_port = 3000
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 0      # Free tier: scale to zero

[env]
  NODE_ENV = "production"
  PORT = "3000"
```

---

## CI Pipeline

```yaml
# .github/workflows/ci.yml
name: CI
on: [pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci
      - run: npm run lint
      - run: npm run build
      - run: npm test
```
