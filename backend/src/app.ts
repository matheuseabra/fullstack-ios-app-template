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
import taskRoutes from './routes/tasks.js'

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
      paths: {
        '/health': {
          get: {
            summary: 'Health check',
            tags: ['Health'],
            responses: {
              '200': {
                description: 'API is healthy',
                content: {
                  'application/json': {
                    schema: {
                      type: 'object',
                      properties: {
                        status: { type: 'string' },
                        ts: { type: 'number' },
                      },
                    },
                  },
                },
              },
            },
          },
        },
        '/auth/webhook/revenuecat': {
          post: {
            summary: 'RevenueCat webhook',
            tags: ['Auth'],
            requestBody: {
              required: true,
              content: { 'application/json': { schema: { type: 'object' } } },
            },
            responses: {
              '200': { description: 'Webhook processed' },
              '401': { description: 'Invalid signature' },
              '400': { description: 'Bad request' },
            },
          },
        },
        '/api/users/me': {
          get: {
            summary: 'Get current user profile',
            tags: ['Users'],
            security: [{ bearerAuth: [] }],
            responses: {
              '200': { description: 'User profile' },
              '401': { description: 'Unauthorized' },
              '404': { description: 'Profile not found' },
            },
          },
          put: {
            summary: 'Update user profile',
            tags: ['Users'],
            security: [{ bearerAuth: [] }],
            requestBody: {
              required: true,
              content: { 'application/json': { schema: { type: 'object' } } },
            },
            responses: {
              '200': { description: 'Profile updated' },
              '401': { description: 'Unauthorized' },
            },
          },
        },
        '/api/users/settings': {
          get: {
            summary: 'Get user settings',
            tags: ['Users'],
            security: [{ bearerAuth: [] }],
            responses: {
              '200': { description: 'User settings' },
              '401': { description: 'Unauthorized' },
            },
          },
          post: {
            summary: 'Upsert user settings',
            tags: ['Users'],
            security: [{ bearerAuth: [] }],
            requestBody: {
              required: true,
              content: { 'application/json': { schema: { type: 'object' } } },
            },
            responses: {
              '200': { description: 'Settings saved' },
              '401': { description: 'Unauthorized' },
            },
          },
        },
        '/api/onboarding/responses': {
          post: {
            summary: 'Submit onboarding responses',
            tags: ['Onboarding'],
            security: [{ bearerAuth: [] }],
            requestBody: {
              required: true,
              content: { 'application/json': { schema: { type: 'object' } } },
            },
            responses: {
              '200': { description: 'Responses saved' },
              '401': { description: 'Unauthorized' },
            },
          },
          get: {
            summary: 'Get onboarding responses',
            tags: ['Onboarding'],
            security: [{ bearerAuth: [] }],
            responses: {
              '200': { description: 'Onboarding responses' },
              '401': { description: 'Unauthorized' },
            },
          },
        },
        '/api/subscriptions/status': {
          get: {
            summary: 'Get subscription status',
            tags: ['Subscriptions'],
            security: [{ bearerAuth: [] }],
            responses: {
              '200': { description: 'Subscription details' },
              '401': { description: 'Unauthorized' },
            },
          },
        },
        '/api/usage/summary': {
          get: {
            summary: 'Get usage summary',
            tags: ['Usage'],
            security: [{ bearerAuth: [] }],
            responses: {
              '200': { description: 'Usage statistics' },
              '401': { description: 'Unauthorized' },
            },
          },
        },
        '/api/usage/logs': {
          get: {
            summary: 'Get usage logs',
            tags: ['Usage'],
            security: [{ bearerAuth: [] }],
            parameters: [
              { name: 'limit', in: 'query', schema: { type: 'integer', default: 50 } },
              { name: 'offset', in: 'query', schema: { type: 'integer', default: 0 } },
            ],
            responses: {
              '200': { description: 'Usage logs' },
              '401': { description: 'Unauthorized' },
            },
          },
          post: {
            summary: 'Log usage event',
            tags: ['Usage'],
            security: [{ bearerAuth: [] }],
            requestBody: {
              required: true,
              content: { 'application/json': { schema: { type: 'object' } } },
            },
            responses: {
              '201': { description: 'Event logged' },
              '401': { description: 'Unauthorized' },
            },
          },
        },
        '/api/notifications/preferences': {
          get: {
            summary: 'Get notification preferences',
            tags: ['Notifications'],
            security: [{ bearerAuth: [] }],
            responses: {
              '200': { description: 'Notification preferences' },
              '401': { description: 'Unauthorized' },
            },
          },
          post: {
            summary: 'Update notification preferences',
            tags: ['Notifications'],
            security: [{ bearerAuth: [] }],
            requestBody: {
              required: true,
              content: { 'application/json': { schema: { type: 'object' } } },
            },
            responses: {
              '200': { description: 'Preferences updated' },
              '401': { description: 'Unauthorized' },
            },
          },
        },
      },
      components: {
        securitySchemes: {
          bearerAuth: {
            type: 'http',
            scheme: 'bearer',
          },
        },
      },
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
app.route('/api/tasks', taskRoutes)

// ─────────────────────────────────────────
// Error handler — must be registered last
// ─────────────────────────────────────────
app.onError(errorHandler)

export default app
