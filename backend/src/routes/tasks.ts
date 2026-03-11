// Route: /api/tasks — CRUD for user tasks
import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import type { AppEnv } from '../types/index.js'
import { supabaseService } from '../services/supabase.js'
import { ok } from '../lib/response.js'
import { AppError } from '../lib/errors.js'
import { createTaskSchema, updateTaskSchema } from '../schemas/task.schema.js'
import type { Database } from '../types/database.js'

const router = new Hono<AppEnv>()
const TASK_SELECT = [
  'id',
  'user_id',
  'title',
  'note',
  'is_completed',
  'priority',
  'due_date',
  'completed_at',
  'created_at',
  'updated_at',
  'category_id',
  'repeat_frequency',
  'series_id',
  'category:task_categories(id, name, emoji, slug, is_default)',
].join(', ')

type TaskRow = Database['public']['Tables']['tasks']['Row']
type TaskCategoryRow = Database['public']['Tables']['task_categories']['Row']
type TaskWithCategoryRow = TaskRow & {
  category?: Pick<TaskCategoryRow, 'id' | 'name' | 'emoji' | 'slug' | 'is_default'> | null
}
type CompleteRecurringTaskResult = Database['public']['Functions']['complete_recurring_task']['Returns'][number]

function serializeTask(task: TaskWithCategoryRow) {
  const category = task.category ?? null

  return {
    id: task.id,
    user_id: task.user_id,
    title: task.title,
    note: task.note ?? '',
    is_completed: task.is_completed,
    priority: task.priority,
    due_date: task.due_date,
    completed_at: task.completed_at,
    created_at: task.created_at,
    updated_at: task.updated_at,
    category_id: task.category_id ?? category?.id ?? null,
    category_name: category?.name ?? null,
    category_emoji: category?.emoji ?? null,
    category_slug: category?.slug ?? null,
    category_is_default: category?.is_default ?? false,
    repeat_frequency: task.repeat_frequency,
    series_id: task.series_id,
  }
}

async function fetchTaskRecord(userId: string, taskId: string) {
  const { data, error } = await supabaseService
    .from('tasks')
    .select('*')
    .eq('id', taskId)
    .eq('user_id', userId)
    .maybeSingle()

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to fetch task')
  return data
}

async function fetchTaskWithCategory(userId: string, taskId: string) {
  const { data, error } = await supabaseService
    .from('tasks')
    .select(TASK_SELECT)
    .eq('id', taskId)
    .eq('user_id', userId)
    .maybeSingle()

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to fetch task')
  return data as TaskWithCategoryRow | null
}

async function assertCategoryAccessible(userId: string, categoryId: string | null | undefined) {
  if (!categoryId) return

  const { data, error } = await supabaseService
    .from('task_categories')
    .select('id, user_id, is_default')
    .eq('id', categoryId)
    .maybeSingle()

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to validate task category')

  if (!data || (!data.is_default && data.user_id !== userId)) {
    throw new AppError(400, 'BAD_REQUEST', 'Invalid task category')
  }
}

function buildUpdatePayload(
  existing: TaskRow,
  body: Partial<Database['public']['Tables']['tasks']['Update']>,
): Database['public']['Tables']['tasks']['Update'] {
  const payload: Database['public']['Tables']['tasks']['Update'] = {}

  if (body.title !== undefined) payload.title = body.title
  if (body.note !== undefined) payload.note = body.note
  if (body.is_completed !== undefined) payload.is_completed = body.is_completed
  if (body.priority !== undefined) payload.priority = body.priority
  if (body.due_date !== undefined) payload.due_date = body.due_date
  if (body.completed_at !== undefined) payload.completed_at = body.completed_at
  if (body.category_id !== undefined) payload.category_id = body.category_id
  if (body.repeat_frequency !== undefined) payload.repeat_frequency = body.repeat_frequency

  const nextRepeatFrequency = body.repeat_frequency === undefined
    ? existing.repeat_frequency
    : body.repeat_frequency

  if (nextRepeatFrequency) {
    if (!existing.series_id) {
      payload.series_id = crypto.randomUUID()
    }
  }

  if (body.repeat_frequency === null) {
    payload.series_id = null
  }

  return payload
}

// GET /api/tasks — list all tasks for the authenticated user
router.get('/', async (c) => {
  const userId = c.get('userId')

  const { data, error } = await supabaseService
    .from('tasks')
    .select(TASK_SELECT)
    .eq('user_id', userId)
    .order('created_at', { ascending: false })

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to fetch tasks')

  return ok(c, ((data ?? []) as unknown as TaskWithCategoryRow[]).map(serializeTask))
})

// GET /api/tasks/:id — get a single task
router.get('/:id', async (c) => {
  const userId = c.get('userId')
  const taskId = c.req.param('id')
  const task = await fetchTaskWithCategory(userId, taskId)

  if (!task) throw new AppError(404, 'NOT_FOUND', 'Task not found')

  return ok(c, serializeTask(task))
})

// POST /api/tasks — create a new task
router.post('/', zValidator('json', createTaskSchema), async (c) => {
  const userId = c.get('userId')
  const body = c.req.valid('json')
  const seriesId = body.repeat_frequency ? crypto.randomUUID() : null

  await assertCategoryAccessible(userId, body.category_id)

  const { data, error } = await supabaseService
    .from('tasks')
    .insert({
      user_id: userId,
      title: body.title,
      note: body.note ?? '',
      is_completed: body.is_completed ?? false,
      priority: body.priority ?? 'medium',
      due_date: body.due_date ?? null,
      completed_at: body.completed_at ?? null,
      category_id: body.category_id ?? null,
      repeat_frequency: body.repeat_frequency ?? null,
      series_id: seriesId,
    })
    .select('id')
    .single()

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to create task')

  const task = await fetchTaskWithCategory(userId, data.id)

  if (!task) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to load created task')

  return ok(c, serializeTask(task), 201)
})

// PUT /api/tasks/:id — update an existing task
router.put('/:id', zValidator('json', updateTaskSchema), async (c) => {
  const userId = c.get('userId')
  const taskId = c.req.param('id')
  const body = c.req.valid('json')
  const existing = await fetchTaskRecord(userId, taskId)

  if (!existing) throw new AppError(404, 'NOT_FOUND', 'Task not found')

  await assertCategoryAccessible(userId, body.category_id)

  const nextRepeatFrequency =
    body.repeat_frequency === undefined ? existing.repeat_frequency : body.repeat_frequency
  const nextDueDate = body.due_date === undefined ? existing.due_date : body.due_date

  if (nextRepeatFrequency && !nextDueDate) {
    throw new AppError(400, 'BAD_REQUEST', 'Recurring tasks require a due date')
  }

  const shouldCompleteRecurring = body.is_completed === true
    && existing.is_completed === false
    && Boolean(nextRepeatFrequency)

  if (shouldCompleteRecurring) {
    const rest = { ...body }
    delete rest.is_completed
    delete rest.completed_at
    const preCompletionPayload = buildUpdatePayload(existing, rest)

    if (Object.keys(preCompletionPayload).length > 0) {
      const { data: preCompletionTask, error: preCompletionError } = await supabaseService
        .from('tasks')
        .update(preCompletionPayload)
        .eq('id', taskId)
        .eq('user_id', userId)
        .select('*')
        .single()

      if (preCompletionError || !preCompletionTask) {
        throw new AppError(404, 'NOT_FOUND', 'Task not found or update failed')
      }
    }

    const { data: completionResult, error: completionError } = await supabaseService.rpc(
      'complete_recurring_task',
      {
        p_task_id: taskId,
        p_user_id: userId,
        p_completed_at: body.completed_at ?? new Date().toISOString(),
      },
    )

    if (completionError) {
      throw new AppError(500, 'INTERNAL_ERROR', 'Failed to complete recurring task')
    }

    const rpcResult = (Array.isArray(completionResult)
      ? completionResult[0]
      : completionResult) as CompleteRecurringTaskResult | undefined

    if (!rpcResult?.current_task_id) {
      throw new AppError(404, 'NOT_FOUND', 'Task not found or update failed')
    }

    const currentTask = await fetchTaskWithCategory(userId, rpcResult.current_task_id)
    const nextTask = rpcResult.next_task_id
      ? await fetchTaskWithCategory(userId, rpcResult.next_task_id)
      : null

    if (!currentTask) {
      throw new AppError(500, 'INTERNAL_ERROR', 'Failed to load updated task')
    }

    return ok(c, {
      task: serializeTask(currentTask),
      next_occurrence: nextTask ? serializeTask(nextTask) : null,
    })
  }

  const payload = buildUpdatePayload(existing, body)

  const { data, error } = await supabaseService
    .from('tasks')
    .update(payload)
    .eq('id', taskId)
    .eq('user_id', userId)
    .select('id')
    .single()

  if (error || !data) throw new AppError(404, 'NOT_FOUND', 'Task not found or update failed')

  const task = await fetchTaskWithCategory(userId, data.id)

  if (!task) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to load updated task')

  return ok(c, { task: serializeTask(task), next_occurrence: null })
})

// DELETE /api/tasks/:id — delete a task
router.delete('/:id', async (c) => {
  const userId = c.get('userId')
  const taskId = c.req.param('id')

  const { error } = await supabaseService
    .from('tasks')
    .delete()
    .eq('id', taskId)
    .eq('user_id', userId)

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to delete task')

  return ok(c, { deleted: true })
})

export default router
