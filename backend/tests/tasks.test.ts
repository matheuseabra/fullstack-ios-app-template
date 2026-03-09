import { supabaseService } from '../src/services/supabase.js'
import tasksRouter from '../src/routes/tasks.js'
import { createTestApp, makeQueryMock, TEST_USER_ID } from './helpers.js'

jest.mock('../src/services/supabase.js', () => ({
  supabaseService: {
    auth: { getUser: jest.fn() },
    from: jest.fn(),
    rpc: jest.fn(),
  },
}))

const app = createTestApp(tasksRouter, '/')
const fromMock = supabaseService.from as jest.Mock
const rpcMock = supabaseService.rpc as jest.Mock

const recurringTask = {
  id: 'task-1',
  user_id: TEST_USER_ID,
  title: 'Workout',
  note: 'Leg day',
  is_completed: false,
  priority: 'medium',
  due_date: '2026-03-09T09:00:00.000Z',
  completed_at: null,
  created_at: '2026-03-08T12:00:00.000Z',
  updated_at: '2026-03-08T12:00:00.000Z',
  category_id: 'default-health',
  repeat_frequency: 'daily',
  series_id: 'series-1',
}

const category = {
  id: 'default-health',
  name: 'Health',
  emoji: '💪',
  slug: 'health',
  is_default: true,
}

describe('GET / tasks', () => {
  it('returns tasks with flattened category fields', async () => {
    fromMock.mockReturnValueOnce(
      makeQueryMock({
        data: [{ ...recurringTask, category }],
        error: null,
      }),
    )

    const res = await app.request('/')
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.data[0].category_name).toBe('Health')
    expect(body.data[0].category_emoji).toBe('💪')
    expect(body.data[0].repeat_frequency).toBe('daily')
  })
})

describe('POST / tasks', () => {
  it('rejects recurring tasks without a due date', async () => {
    const res = await app.request('/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: 'Drink water', repeat_frequency: 'daily' }),
    })

    expect(res.status).toBe(400)
  })

  it('rejects inaccessible categories', async () => {
    fromMock.mockReturnValueOnce(makeQueryMock({ data: null, error: null }))

    const res = await app.request('/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: 'Plan sprint',
        due_date: '2026-03-09T10:00:00.000Z',
        category_id: '11111111-1111-4111-8111-111111111111',
      }),
    })
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(400)
    expect(body.error.code).toBe('BAD_REQUEST')
  })

  it('creates a recurring task', async () => {
    fromMock.mockReturnValueOnce(makeQueryMock({ data: { id: 'task-99' }, error: null }))
    fromMock.mockReturnValueOnce(
      makeQueryMock({
        data: {
          ...recurringTask,
          id: 'task-99',
          category,
        },
        error: null,
      }),
    )

    const res = await app.request('/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: 'Workout',
        note: 'Leg day',
        due_date: '2026-03-09T09:00:00.000Z',
        repeat_frequency: 'daily',
        priority: 'medium',
      }),
    })
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(201)
    expect(body.data.repeat_frequency).toBe('daily')
    expect(body.data.series_id).toBeTruthy()
  })
})

describe('PUT /:id tasks', () => {
  it('rejects enabling recurrence without a due date', async () => {
    fromMock.mockReturnValueOnce(
      makeQueryMock({
        data: { ...recurringTask, repeat_frequency: null, due_date: null, series_id: null },
        error: null,
      }),
    )

    const res = await app.request('/task-1', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ repeat_frequency: 'weekly' }),
    })
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(400)
    expect(body.error.code).toBe('BAD_REQUEST')
  })

  it('completes a recurring task and returns the next occurrence', async () => {
    fromMock.mockReturnValueOnce(makeQueryMock({ data: recurringTask, error: null }))
    rpcMock.mockResolvedValueOnce({
      data: [{ current_task_id: 'task-1', next_task_id: 'task-2' }],
      error: null,
    })
    fromMock.mockReturnValueOnce(
      makeQueryMock({
        data: {
          ...recurringTask,
          is_completed: true,
          completed_at: '2026-03-09T09:05:00.000Z',
          category,
        },
        error: null,
      }),
    )
    fromMock.mockReturnValueOnce(
      makeQueryMock({
        data: {
          ...recurringTask,
          id: 'task-2',
          due_date: '2026-03-10T09:00:00.000Z',
          category,
        },
        error: null,
      }),
    )

    const res = await app.request('/task-1', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ is_completed: true }),
    })
    const body = await res.json() as Record<string, any>

    expect(res.status).toBe(200)
    expect(body.data.task.is_completed).toBe(true)
    expect(body.data.next_occurrence.id).toBe('task-2')
    expect(body.data.next_occurrence.due_date).toBe('2026-03-10T09:00:00.000Z')
    expect(rpcMock).toHaveBeenCalledWith('complete_recurring_task', expect.objectContaining({
      p_task_id: 'task-1',
      p_user_id: TEST_USER_ID,
    }))
  })
})