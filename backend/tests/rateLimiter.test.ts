import { Hono } from 'hono'
import { rateLimiter } from '../src/middleware/rateLimiter.js'
import { errorHandler } from '../src/middleware/errorHandler.js'
import { memoryStore } from '../src/services/redis.js'

// Use in-memory fallback (Redis is not available in CI)
jest.mock('../src/services/redis.js', () => ({
  redis: null, // forces in-memory path
  memoryStore: new Map(),
}))

function buildApp(limit: number) {
  const app = new Hono()
  // Inject a fake userId so the rate limiter key is consistent
  app.use('*', async (c, next) => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    ;(c as any).set('userId', 'rate-limit-test-user')
    await next()
  })
  app.use('*', rateLimiter({ requests: limit, window: '1m' }))
  app.get('/test', (c) => c.json({ ok: true }))
  app.onError(errorHandler)
  return app
}

beforeEach(() => {
  memoryStore.clear()
})

describe('rateLimiter middleware (in-memory)', () => {
  it('allows requests under the limit', async () => {
    const app = buildApp(5)

    const res = await app.request('/test')
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.ok).toBe(true)
    expect(res.headers.get('X-RateLimit-Limit')).toBe('5')
    expect(res.headers.get('X-RateLimit-Remaining')).toBe('4')
  })

  it('decrements remaining on each request', async () => {
    const app = buildApp(3)

    await app.request('/test')
    await app.request('/test')
    const res = await app.request('/test')

    expect(res.status).toBe(200)
    expect(res.headers.get('X-RateLimit-Remaining')).toBe('0')
  })

  it('returns 429 when limit is exceeded', async () => {
    const app = buildApp(2)

    await app.request('/test')
    await app.request('/test')
    const res = await app.request('/test') // 3rd request = over limit
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(429)
    expect(body.error.code).toBe('RATE_LIMITED')
    expect(res.headers.get('X-RateLimit-Remaining')).toBe('0')
  })

  it('sets X-RateLimit-Limit header to the configured limit', async () => {
    const app = buildApp(100)

    const res = await app.request('/test')

    expect(res.headers.get('X-RateLimit-Limit')).toBe('100')
  })

  it('resets count after window expires', async () => {
    const app = buildApp(1)

    // First request — under limit
    let res = await app.request('/test')
    expect(res.status).toBe(200)

    // Second request — over limit
    res = await app.request('/test')
    expect(res.status).toBe(429)

    // Manually expire the window entry
    memoryStore.forEach((v, k) => {
      memoryStore.set(k, { ...v, expiresAt: Date.now() - 1 })
    })

    // Request after expiry — counter resets
    res = await app.request('/test')
    expect(res.status).toBe(200)
  })
})
