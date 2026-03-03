import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { secureHeaders } from 'hono/secure-headers'
import { swaggerUI } from '@hono/swagger-ui'

import { env } from './types/env.js'
import type { AppEnv } from './types/index.js'

import { authMiddleware } from './middleware/auth.js'
import { rateLimiter } from './middleware/rateLimiter.js'
import { requestLogger } from './middleware/requestLogger.js'
import { errorHandler } from './middleware/errorHandler.js'

import authRoutes from './routes/auth.js'
import userRoutes from './routes/users.js'
import onboardingRoutes from './routes/onboarding.js'
import subscriptionRoutes from './routes/subscriptions.js'
import usageRoutes from './routes/usage.js'
import notificationRoutes from './routes/notifications.js'

const app = new Hono<AppEnv>()

// ─────────────────────────────────────────
// Global middleware
// ─────────────────────────────────────────
app.use(
  '*',
  cors({
    origin: env.ALLOWED_ORIGINS.split(',').map((o) => o.trim()),
    credentials: true,
  }),
)
app.use('*', secureHeaders())
app.use('*', requestLogger)

// ─────────────────────────────────────────
// OpenAPI / Swagger UI (dev only)
// ─────────────────────────────────────────
if (env.NODE_ENV === 'development') {
  app.get('/docs', swaggerUI({ url: '/openapi' }))
  app.get('/openapi', (c) =>
    c.json({
      openapi: '3.0.0',
      info: { title: 'App API', version: '1.0.0' },
      paths: {},
    }),
  )
}

// ─────────────────────────────────────────
// Health check — no auth required
// ─────────────────────────────────────────
app.get('/health', (c) => c.json({ status: 'ok', ts: Date.now() }))

// ─────────────────────────────────────────
// Public routes
// ─────────────────────────────────────────
app.route('/auth', authRoutes)

// ─────────────────────────────────────────
// Protected routes — auth + rate limit applied globally
// ─────────────────────────────────────────
app.use('/api/*', authMiddleware)
app.use('/api/*', rateLimiter({ requests: 100, window: '1m' }))

app.route('/api/users', userRoutes)
app.route('/api/onboarding', onboardingRoutes)
app.route('/api/subscriptions', subscriptionRoutes)
app.route('/api/usage', usageRoutes)
app.route('/api/notifications', notificationRoutes)

// ─────────────────────────────────────────
// Error handler — must be registered last
// ─────────────────────────────────────────
app.onError(errorHandler)

export default app
