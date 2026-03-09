import { supabaseService } from '../src/services/supabase.js'
import taskCategoriesRouter from '../src/routes/taskCategories.js'
import { createTestApp, makeQueryMock, TEST_USER_ID } from './helpers.js'

jest.mock('../src/services/supabase.js', () => ({
  supabaseService: {
    auth: { getUser: jest.fn() },
    from: jest.fn(),
  },
}))

const app = createTestApp(taskCategoriesRouter, '/')
const fromMock = supabaseService.from as jest.Mock

describe('GET / task categories', () => {
  it('returns default and user-defined categories', async () => {
    fromMock.mockReturnValueOnce(
      makeQueryMock({
        data: [
          {
            id: 'default-health',
            user_id: null,
            name: 'Health',
            emoji: '💪',
            slug: 'health',
            is_default: true,
            created_at: '2026-03-09T00:00:00.000Z',
            updated_at: '2026-03-09T00:00:00.000Z',
          },
          {
            id: 'custom-focus',
            user_id: TEST_USER_ID,
            name: 'Deep Focus',
            emoji: '🧠',
            slug: null,
            is_default: false,
            created_at: '2026-03-09T00:00:00.000Z',
            updated_at: '2026-03-09T00:00:00.000Z',
          },
        ],
        error: null,
      }),
    )

    const res = await app.request('/')
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.ok).toBe(true)
    expect(body.data).toHaveLength(2)
    expect(body.data[0].is_default).toBe(true)
    expect(body.data[1].user_id).toBe(TEST_USER_ID)
    expect(fromMock).toHaveBeenCalledWith('task_categories')
  })
})

describe('POST / task categories', () => {
  it('creates a custom category', async () => {
    fromMock.mockReturnValueOnce(
      makeQueryMock({
        data: {
          id: 'custom-social',
          user_id: TEST_USER_ID,
          name: 'Friends',
          emoji: '🎉',
          slug: null,
          is_default: false,
          created_at: '2026-03-09T00:00:00.000Z',
          updated_at: '2026-03-09T00:00:00.000Z',
        },
        error: null,
      }),
    )

    const res = await app.request('/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Friends', emoji: '🎉' }),
    })
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(201)
    expect(body.data.name).toBe('Friends')
    expect(body.data.emoji).toBe('🎉')
  })

  it('returns 400 on invalid payload', async () => {
    const res = await app.request('/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: '', emoji: '' }),
    })

    expect(res.status).toBe(400)
  })
})