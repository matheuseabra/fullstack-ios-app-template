import { Hono } from 'hono'
import type { AppEnv } from '../src/types/index.js'
import { errorHandler } from '../src/middleware/errorHandler.js'

export const TEST_USER_ID = 'aaaaaaaa-0000-0000-0000-000000000001'
export const TEST_USER = {
  id: TEST_USER_ID,
  email: 'test@example.com',
  app_metadata: {},
  user_metadata: {},
  aud: 'authenticated',
  created_at: '2024-01-01T00:00:00.000Z',
}

/**
 * Wraps a route router in a minimal Hono app with a mock auth middleware
 * that pre-sets userId/user on the context — no real JWT needed.
 */
export function createTestApp(router: Hono<AppEnv>, mountPath = '/') {
  const app = new Hono<AppEnv>()

  // Mock auth: skip token validation, inject test user
  app.use('*', async (c, next) => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    c.set('user', TEST_USER as any)
    c.set('userId', TEST_USER_ID)
    await next()
  })

  app.route(mountPath, router)
  app.onError(errorHandler)
  return app
}

/**
 * Builds a fluent Supabase query mock whose terminal methods resolve to `value`.
 * The chain is also thenable so directly-awaited builders (insert, upsert) work.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function makeQueryMock(value: unknown = { data: null, error: null }): any {
  const chain: Record<string, unknown> = {
    select: jest.fn().mockReturnThis(),
    eq: jest.fn().mockReturnThis(),
    update: jest.fn().mockReturnThis(),
    upsert: jest.fn().mockReturnThis(),
    insert: jest.fn().mockReturnThis(),
    maybeSingle: jest.fn().mockResolvedValue(value),
    single: jest.fn().mockResolvedValue(value),
    gte: jest.fn().mockReturnThis(),
    // Thenable: handles `await chain` when no explicit terminal is called
    then: (
      resolve: (v: unknown) => unknown,
      reject?: (e: unknown) => unknown,
    ) => Promise.resolve(value).then(resolve, reject),
  }
  return chain
}

// Reset all mocks between tests — clears call history AND unconsumed mockReturnValueOnce queues
afterEach(() => {
  jest.resetAllMocks()
})
