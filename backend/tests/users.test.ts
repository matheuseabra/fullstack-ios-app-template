import { supabaseService } from '../src/services/supabase.js'
import usersRouter from '../src/routes/users.js'
import { createTestApp, makeQueryMock, TEST_USER_ID } from './helpers.js'

jest.mock('../src/services/supabase.js', () => ({
  supabaseService: {
    auth: { getUser: jest.fn() },
    from: jest.fn(),
  },
}))

const app = createTestApp(usersRouter, '/')
const fromMock = supabaseService.from as jest.Mock

const mockProfile = {
  id: TEST_USER_ID,
  email: 'test@example.com',
  full_name: 'Test User',
  avatar_url: null,
  timezone: 'UTC',
  locale: 'en',
  created_at: '2024-01-01T00:00:00.000Z',
  updated_at: '2024-01-01T00:00:00.000Z',
}

describe('GET /me', () => {
  it('returns the user profile', async () => {
    fromMock.mockReturnValueOnce(makeQueryMock({ data: mockProfile, error: null }))

    const res = await app.request('/me')
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.ok).toBe(true)
    expect(body.data.id).toBe(TEST_USER_ID)
    expect(fromMock).toHaveBeenCalledWith('profiles')
  })

  it('returns 404 when profile does not exist', async () => {
    fromMock.mockReturnValueOnce(makeQueryMock({ data: null, error: null }))

    const res = await app.request('/me')
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(404)
    expect(body.ok).toBe(false)
    expect(body.error.code).toBe('NOT_FOUND')
  })

  it('returns 500 on database error', async () => {
    fromMock.mockReturnValueOnce(
      makeQueryMock({ data: null, error: { message: 'connection refused' } }),
    )

    const res = await app.request('/me')
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(500)
    expect(body.error.code).toBe('INTERNAL_ERROR')
  })
})

describe('PUT /me', () => {
  it('updates and returns the profile', async () => {
    const updated = { ...mockProfile, full_name: 'Updated Name' }
    fromMock.mockReturnValueOnce(makeQueryMock({ data: updated, error: null }))

    const res = await app.request('/me', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ full_name: 'Updated Name' }),
    })
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.data.full_name).toBe('Updated Name')
  })

  it('returns 400 on invalid payload', async () => {
    const res = await app.request('/me', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ avatar_url: 'not-a-url' }),
    })

    expect(res.status).toBe(400)
  })
})

describe('GET /me/settings', () => {
  it('returns settings as a key-value map', async () => {
    const rows = [
      { key: 'theme', value: 'dark', updated_at: '2024-01-01T00:00:00.000Z' },
      { key: 'lang', value: 'en', updated_at: '2024-01-01T00:00:00.000Z' },
    ]
    fromMock.mockReturnValueOnce(makeQueryMock({ data: rows, error: null }))

    const res = await app.request('/me/settings')
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.data).toEqual({ theme: 'dark', lang: 'en' })
  })

  it('returns empty map when no settings exist', async () => {
    fromMock.mockReturnValueOnce(makeQueryMock({ data: [], error: null }))

    const res = await app.request('/me/settings')
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.data).toEqual({})
  })
})

describe('PUT /me/settings', () => {
  it('upserts a setting and returns it', async () => {
    const row = { key: 'theme', value: 'dark', updated_at: '2024-01-01T00:00:00.000Z' }
    fromMock.mockReturnValueOnce(makeQueryMock({ data: row, error: null }))

    const res = await app.request('/me/settings', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ key: 'theme', value: 'dark' }),
    })
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.data.key).toBe('theme')
    expect(body.data.value).toBe('dark')
  })

  it('returns 400 when key is missing', async () => {
    const res = await app.request('/me/settings', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ value: 'dark' }),
    })

    expect(res.status).toBe(400)
  })
})
