import { Hono } from 'hono'
import { supabaseService } from '../src/services/supabase.js'
import { authMiddleware } from '../src/middleware/auth.js'
import { errorHandler } from '../src/middleware/errorHandler.js'
import type { AppEnv } from '../src/types/index.js'

jest.mock('../src/services/supabase.js', () => ({
  supabaseService: {
    auth: { getUser: jest.fn() },
    from: jest.fn(),
  },
}))

const getUser = supabaseService.auth.getUser as jest.Mock

const mockUser = {
  id: 'test-user-id',
  email: 'test@example.com',
  app_metadata: {},
  user_metadata: {},
  aud: 'authenticated',
  created_at: '2024-01-01T00:00:00.000Z',
}

// Minimal test app that applies authMiddleware and returns the user context
function buildApp() {
  const app = new Hono<AppEnv>()
  app.use('*', authMiddleware)
  app.get('/protected', (c) =>
    c.json({ userId: c.get('userId'), email: c.get('user').email }),
  )
  app.onError(errorHandler)
  return app
}

describe('authMiddleware', () => {
  it('sets user and userId on context with a valid token', async () => {
    getUser.mockResolvedValueOnce({ data: { user: mockUser }, error: null })

    const app = buildApp()
    const res = await app.request('/protected', {
      headers: { Authorization: 'Bearer valid-token' },
    })
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.userId).toBe('test-user-id')
    expect(body.email).toBe('test@example.com')
    expect(getUser).toHaveBeenCalledWith('valid-token')
  })

  it('returns 401 when Authorization header is missing', async () => {
    const app = buildApp()
    const res = await app.request('/protected')
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(401)
    expect(body.error.code).toBe('UNAUTHORIZED')
    expect(getUser).not.toHaveBeenCalled()
  })

  it('returns 401 when token is invalid or expired', async () => {
    getUser.mockResolvedValueOnce({
      data: { user: null },
      error: { message: 'JWT expired' },
    })

    const app = buildApp()
    const res = await app.request('/protected', {
      headers: { Authorization: 'Bearer expired-token' },
    })
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(401)
    expect(body.error.code).toBe('UNAUTHORIZED')
  })

  it('returns 401 when Supabase returns null user without an error', async () => {
    getUser.mockResolvedValueOnce({ data: { user: null }, error: null })

    const app = buildApp()
    const res = await app.request('/protected', {
      headers: { Authorization: 'Bearer some-token' },
    })

    expect(res.status).toBe(401)
  })

  it('strips "Bearer " prefix before calling getUser', async () => {
    getUser.mockResolvedValueOnce({ data: { user: mockUser }, error: null })

    const app = buildApp()
    await app.request('/protected', {
      headers: { Authorization: 'Bearer my-jwt-token' },
    })

    expect(getUser).toHaveBeenCalledWith('my-jwt-token')
  })
})

// Suppress unhandled AppError noise in test output
beforeAll(() => {
  jest.spyOn(console, 'error').mockImplementation(() => {})
})
afterEach(() => {
  jest.clearAllMocks()
})
afterAll(() => {
  jest.restoreAllMocks()
})
