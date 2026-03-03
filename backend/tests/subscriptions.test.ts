import { supabaseService } from '../src/services/supabase.js'
import * as revenuecatService from '../src/services/revenuecat.js'
import authRouter from '../src/routes/auth.js'
import subscriptionsRouter from '../src/routes/subscriptions.js'
import { createTestApp, makeQueryMock, TEST_USER_ID } from './helpers.js'

jest.mock('../src/services/supabase.js', () => ({
  supabaseService: {
    auth: { getUser: jest.fn() },
    from: jest.fn(),
  },
}))

jest.mock('../src/services/revenuecat.js', () => ({
  validateRevenueCatSignature: jest.fn(),
  getRevenueCatSubscriber: jest.fn(),
}))

const webhookApp = createTestApp(authRouter, '/')
const subscriptionsApp = createTestApp(subscriptionsRouter, '/')

const fromMock = supabaseService.from as jest.Mock
const validateSig = revenuecatService.validateRevenueCatSignature as jest.Mock

const validWebhookPayload = {
  event: {
    type: 'INITIAL_PURCHASE',
    app_user_id: TEST_USER_ID,
    product_id: 'annual_pro',
    expiration_at_ms: Date.now() + 365 * 24 * 60 * 60 * 1000,
    entitlement_ids: ['pro'],
  },
}

describe('POST /webhook/revenuecat', () => {
  it('processes a valid INITIAL_PURCHASE event and upserts subscription', async () => {
    validateSig.mockReturnValue(true)
    fromMock.mockReturnValueOnce(makeQueryMock({ error: null }))

    const res = await webhookApp.request('/webhook/revenuecat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-RevenueCat-Signature': 'valid-sig',
      },
      body: JSON.stringify(validWebhookPayload),
    })
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.received).toBe(true)
    expect(fromMock).toHaveBeenCalledWith('subscriptions')
  })

  it('acks unknown event types without writing to DB', async () => {
    validateSig.mockReturnValue(true)

    const res = await webhookApp.request('/webhook/revenuecat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-RevenueCat-Signature': 'valid-sig',
      },
      body: JSON.stringify({
        event: { type: 'SUBSCRIBER_ALIAS', app_user_id: TEST_USER_ID },
      }),
    })
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.received).toBe(true)
    expect(fromMock).not.toHaveBeenCalled()
  })

  it('returns 401 when signature is invalid', async () => {
    validateSig.mockReturnValue(false)

    const res = await webhookApp.request('/webhook/revenuecat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-RevenueCat-Signature': 'bad' },
      body: JSON.stringify(validWebhookPayload),
    })
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(401)
    expect(body.error.code).toBe('INVALID_SIGNATURE')
  })

  it('returns 400 on invalid payload shape', async () => {
    validateSig.mockReturnValue(true)

    const res = await webhookApp.request('/webhook/revenuecat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-RevenueCat-Signature': 'valid' },
      body: JSON.stringify({ not_event: true }),
    })

    expect(res.status).toBe(400)
  })
})

describe('GET /me (subscriptions)', () => {
  const mockSub = {
    id: 'sub-1',
    product_id: 'annual_pro',
    status: 'active',
    trial_ends_at: null,
    current_period_end: '2025-01-01T00:00:00.000Z',
    cancel_at_period_end: false,
    entitlements: { ids: ['pro'] },
    created_at: '2024-01-01T00:00:00.000Z',
    updated_at: '2024-01-01T00:00:00.000Z',
  }

  it('returns the active subscription', async () => {
    fromMock.mockReturnValueOnce(makeQueryMock({ data: mockSub, error: null }))

    const res = await subscriptionsApp.request('/me')
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.data.status).toBe('active')
    expect(body.data.product_id).toBe('annual_pro')
  })

  it('returns null when user has no subscription (free tier)', async () => {
    fromMock.mockReturnValueOnce(makeQueryMock({ data: null, error: null }))

    const res = await subscriptionsApp.request('/me')
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.data).toBeNull()
  })
})
