// Route: /api/subscriptions — subscription status
import { Hono } from 'hono'
import type { AppEnv } from '../types/index.js'
import { supabaseService } from '../services/supabase.js'
import { ok } from '../lib/response.js'
import { AppError } from '../lib/errors.js'

const router = new Hono<AppEnv>()

// GET /api/subscriptions/me — get own subscription status
router.get('/me', async (c) => {
  const userId = c.get('userId')

  const { data, error } = await supabaseService
    .from('subscriptions')
    .select(
      'id, product_id, status, trial_ends_at, current_period_end, cancel_at_period_end, entitlements, created_at, updated_at',
    )
    .eq('user_id', userId)
    .maybeSingle()

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to fetch subscription')

  // Return null when no subscription row exists — client should treat as free tier
  return ok(c, data ?? null)
})

export default router
