import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import type { AppEnv } from '../types/index.js'
import { supabaseService } from '../services/supabase.js'
import { ok } from '../lib/response.js'
import { AppError } from '../lib/errors.js'
import { createTaskCategorySchema } from '../schemas/taskCategory.schema.js'

const router = new Hono<AppEnv>()

router.get('/', async (c) => {
  const userId = c.get('userId')

  const { data, error } = await supabaseService
    .from('task_categories')
    .select('id, user_id, name, emoji, slug, is_default, created_at, updated_at')
    .or(`is_default.eq.true,user_id.eq.${userId}`)
    .order('is_default', { ascending: false })
    .order('name', { ascending: true })

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to fetch task categories')

  return ok(c, data ?? [])
})

router.post('/', zValidator('json', createTaskCategorySchema), async (c) => {
  const userId = c.get('userId')
  const body = c.req.valid('json')

  const { data, error } = await supabaseService
    .from('task_categories')
    .insert({
      user_id: userId,
      name: body.name,
      emoji: body.emoji,
      is_default: false,
      slug: null,
    })
    .select('id, user_id, name, emoji, slug, is_default, created_at, updated_at')
    .single()

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to create task category')

  return ok(c, data, 201)
})

export default router