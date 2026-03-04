// Route: /api/tasks — CRUD for user tasks
import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import type { AppEnv } from '../types/index.js'
import { supabaseService } from '../services/supabase.js'
import { ok } from '../lib/response.js'
import { AppError } from '../lib/errors.js'
import { createTaskSchema, updateTaskSchema } from '../schemas/task.schema.js'

const router = new Hono<AppEnv>()

// GET /api/tasks — list all tasks for the authenticated user
router.get('/', async (c) => {
  const userId = c.get('userId')

  const { data, error } = await supabaseService
    .from('tasks')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to fetch tasks')

  return ok(c, data)
})

// GET /api/tasks/:id — get a single task
router.get('/:id', async (c) => {
  const userId = c.get('userId')
  const taskId = c.req.param('id')

  const { data, error } = await supabaseService
    .from('tasks')
    .select('*')
    .eq('id', taskId)
    .eq('user_id', userId)
    .single()

  if (error || !data) throw new AppError(404, 'NOT_FOUND', 'Task not found')

  return ok(c, data)
})

// POST /api/tasks — create a new task
router.post('/', zValidator('json', createTaskSchema), async (c) => {
  const userId = c.get('userId')
  const body = c.req.valid('json')

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
    })
    .select()
    .single()

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to create task')

  return ok(c, data, 201)
})

// PUT /api/tasks/:id — update an existing task
router.put('/:id', zValidator('json', updateTaskSchema), async (c) => {
  const userId = c.get('userId')
  const taskId = c.req.param('id')
  const body = c.req.valid('json')

  const { data, error } = await supabaseService
    .from('tasks')
    .update(body)
    .eq('id', taskId)
    .eq('user_id', userId)
    .select()
    .single()

  if (error || !data) throw new AppError(404, 'NOT_FOUND', 'Task not found or update failed')

  return ok(c, data)
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
