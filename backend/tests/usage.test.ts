import { supabaseService } from '../src/services/supabase.js'
import usageRouter from '../src/routes/usage.js'
import { createTestApp, makeQueryMock } from './helpers.js'

jest.mock('../src/services/supabase.js', () => ({
  supabaseService: {
    auth: { getUser: jest.fn() },
    from: jest.fn(),
  },
}))

const app = createTestApp(usageRouter, '/')
const fromMock = supabaseService.from as jest.Mock

describe('GET /:feature', () => {
  it('returns usage stats for a free-tier user', async () => {
    // First from() call: subscriptions (no subscription = free tier)
    fromMock.mockReturnValueOnce(makeQueryMock({ data: null, error: null }))
    // Second from() call: usage_logs count
    fromMock.mockReturnValueOnce(makeQueryMock({ count: 3, error: null }))

    const res = await app.request('/ai_generation')
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.data).toMatchObject({
      feature: 'ai_generation',
      used: 3,
      limit: 10,
      remaining: 7,
      is_paid: false,
    })
    expect(fromMock).toHaveBeenCalledWith('subscriptions')
    expect(fromMock).toHaveBeenCalledWith('usage_logs')
  })

  it('returns higher limits for a paid-tier user', async () => {
    fromMock.mockReturnValueOnce(makeQueryMock({ data: { status: 'active' }, error: null }))
    fromMock.mockReturnValueOnce(makeQueryMock({ count: 10, error: null }))

    const res = await app.request('/ai_generation')
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.data.limit).toBe(100)
    expect(body.data.is_paid).toBe(true)
    expect(body.data.remaining).toBe(90)
  })

  it('returns remaining: 0 when usage equals the limit', async () => {
    fromMock.mockReturnValueOnce(makeQueryMock({ data: null, error: null }))
    fromMock.mockReturnValueOnce(makeQueryMock({ count: 10, error: null }))

    const res = await app.request('/ai_generation')
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.data.remaining).toBe(0)
  })
})

describe('POST /:feature', () => {
  it('logs a usage event', async () => {
    fromMock.mockReturnValueOnce(makeQueryMock({ error: null }))

    const res = await app.request('/ai_generation', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ metadata: { model: 'gpt-4' } }),
    })
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(201)
    expect(body.data.logged).toBe(true)
    expect(fromMock).toHaveBeenCalledWith('usage_logs')
  })

  it('logs a usage event with no metadata (empty body)', async () => {
    fromMock.mockReturnValueOnce(makeQueryMock({ error: null }))

    const res = await app.request('/test_feature', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    })

    // Empty body is valid — metadata is optional
    expect(res.status).toBe(201)
  })

  it('returns 500 on database error', async () => {
    fromMock.mockReturnValueOnce(makeQueryMock({ error: { message: 'insert failed' } }))

    const res = await app.request('/ai_generation', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    })
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(500)
    expect(body.error.code).toBe('INTERNAL_ERROR')
  })
})
