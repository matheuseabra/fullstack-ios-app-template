import { supabaseService } from '../src/services/supabase.js'
import onboardingRouter from '../src/routes/onboarding.js'
import { createTestApp, makeQueryMock } from './helpers.js'

jest.mock('../src/services/supabase.js', () => ({
  supabaseService: {
    auth: { getUser: jest.fn() },
    from: jest.fn(),
  },
}))

const app = createTestApp(onboardingRouter, '/')
const fromMock = supabaseService.from as jest.Mock

const validResponses = [
  { question_key: 'goal', answer: 'lose_weight' },
  { question_key: 'frequency', answer: 3 },
]

describe('POST /responses', () => {
  it('saves responses and returns saved count', async () => {
    const savedRows = validResponses.map((r) => ({
      ...r,
      created_at: '2024-01-01T00:00:00.000Z',
    }))
    fromMock.mockReturnValueOnce(makeQueryMock({ data: savedRows, error: null }))

    const res = await app.request('/responses', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ responses: validResponses }),
    })
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(201)
    expect(body.ok).toBe(true)
    expect(body.data.saved).toBe(2)
    expect(fromMock).toHaveBeenCalledWith('onboarding_responses')
  })

  it('returns 400 when responses array is empty', async () => {
    const res = await app.request('/responses', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ responses: [] }),
    })

    expect(res.status).toBe(400)
  })

  it('returns 400 when responses field is missing', async () => {
    const res = await app.request('/responses', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    })

    expect(res.status).toBe(400)
  })

  it('returns 500 on database error', async () => {
    fromMock.mockReturnValueOnce(
      makeQueryMock({ data: null, error: { message: 'unique violation' } }),
    )

    const res = await app.request('/responses', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ responses: validResponses }),
    })
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(500)
    expect(body.error.code).toBe('INTERNAL_ERROR')
  })
})
