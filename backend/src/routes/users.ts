// Route: /api/users — profile + settings
import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import type { AppEnv } from '../types/index.js'
import { supabaseService } from '../services/supabase.js'
import { ok } from '../lib/response.js'
import { AppError } from '../lib/errors.js'
import { updateProfileSchema, upsertSettingSchema } from '../schemas/user.schema.js'
import type { Json } from '../types/database.js'

const router = new Hono<AppEnv>()

// GET /api/users/me — fetch own profile
router.get('/me', async (c) => {
  const userId = c.get('userId')

  const { data, error } = await supabaseService
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .maybeSingle()

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to fetch profile')
  if (!data) throw new AppError(404, 'NOT_FOUND', 'Profile not found')

  return ok(c, data)
})

// PUT /api/users/me — update own profile
router.put('/me', zValidator('json', updateProfileSchema), async (c) => {
  const userId = c.get('userId')
  const body = c.req.valid('json')

  const { data, error } = await supabaseService
    .from('profiles')
    .update(body)
    .eq('id', userId)
    .select()
    .single()

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to update profile')

  return ok(c, data)
})

// GET /api/users/me/settings — list all settings for own user
router.get('/me/settings', async (c) => {
  const userId = c.get('userId')

  const { data, error } = await supabaseService
    .from('user_settings')
    .select('key, value, updated_at')
    .eq('user_id', userId)

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to fetch settings')

  // Return as a flat key→value map for convenience
  const settings = Object.fromEntries((data ?? []).map(({ key, value }) => [key, value]))
  return ok(c, settings)
})

// PUT /api/users/me/settings — upsert a single setting by key
router.put('/me/settings', zValidator('json', upsertSettingSchema), async (c) => {
  const userId = c.get('userId')
  const { key, value } = c.req.valid('json')

  const { data, error } = await supabaseService
    .from('user_settings')
    .upsert(
      { user_id: userId, key, value: value as Json },
      { onConflict: 'user_id,key' },
    )
    .select('key, value, updated_at')
    .single()

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to upsert setting')

  return ok(c, data)
})

export default router
