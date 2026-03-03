// Route: /api/notifications — push token + preferences
import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import type { AppEnv } from '../types/index.js'
import { supabaseService } from '../services/supabase.js'
import { ok } from '../lib/response.js'
import { AppError } from '../lib/errors.js'
import {
  registerTokenSchema,
  updatePreferencesSchema,
} from '../schemas/notification.schema.js'

const router = new Hono<AppEnv>()

// PUT /api/notifications/token — register or update APNs push token
router.put('/token', zValidator('json', registerTokenSchema), async (c) => {
  const userId = c.get('userId')
  const { push_token } = c.req.valid('json')

  const { error } = await supabaseService
    .from('notification_preferences')
    .upsert({ user_id: userId, push_token }, { onConflict: 'user_id' })

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to register push token')

  return ok(c, { registered: true })
})

// GET /api/notifications/preferences — get notification preferences
router.get('/preferences', async (c) => {
  const userId = c.get('userId')

  const { data, error } = await supabaseService
    .from('notification_preferences')
    .select('enabled, reminder_time, days_of_week, updated_at')
    .eq('user_id', userId)
    .maybeSingle()

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to fetch notification preferences')

  // Return defaults if no preferences row has been created yet
  return ok(
    c,
    data ?? {
      enabled: false,
      reminder_time: null,
      days_of_week: [],
      updated_at: null,
    },
  )
})

// PUT /api/notifications/preferences — update notification preferences
router.put(
  '/preferences',
  zValidator('json', updatePreferencesSchema),
  async (c) => {
    const userId = c.get('userId')
    const body = c.req.valid('json')

    const { data, error } = await supabaseService
      .from('notification_preferences')
      .upsert({ user_id: userId, ...body }, { onConflict: 'user_id' })
      .select('enabled, reminder_time, days_of_week, updated_at')
      .single()

    if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to update notification preferences')

    return ok(c, data)
  },
)

export default router
