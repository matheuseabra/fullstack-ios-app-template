// Route: /api/usage — feature cap checks + usage logging
import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import type { AppEnv } from '../types/index.js'
import { supabaseService } from '../services/supabase.js'
import { ok } from '../lib/response.js'
import { AppError } from '../lib/errors.js'
import { logUsageSchema } from '../schemas/usage.schema.js'
import type { Json } from '../types/database.js'

const router = new Hono<AppEnv>()

// GET /api/usage/:feature — check remaining usage for a feature today
router.get('/:feature', async (c) => {
  const userId = c.get('userId')
  const feature = c.req.param('feature')

  // Determine subscription tier
  const { data: sub } = await supabaseService
    .from('subscriptions')
    .select('status')
    .eq('user_id', userId)
    .maybeSingle()

  const isPaid = ['trial', 'active'].includes(sub?.status ?? '')

  // Count today's usage (UTC day boundary)
  const todayStart = new Date()
  todayStart.setUTCHours(0, 0, 0, 0)

  const { count, error } = await supabaseService
    .from('usage_logs')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .eq('feature', feature)
    .gte('created_at', todayStart.toISOString())

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to check usage')

  // Default limits — adjust per feature by adding route-specific middleware (usageCap) as needed
  const freeLimit = 10
  const paidLimit = 100
  const limit = isPaid ? paidLimit : freeLimit
  const used = count ?? 0

  return ok(c, {
    feature,
    used,
    limit,
    remaining: Math.max(0, limit - used),
    is_paid: isPaid,
  })
})

// POST /api/usage/:feature — log a usage event
router.post('/:feature', zValidator('json', logUsageSchema), async (c) => {
  const userId = c.get('userId')
  const feature = c.req.param('feature')
  const body = c.req.valid('json')

  const { error } = await supabaseService.from('usage_logs').insert({
    user_id: userId,
    feature,
    count: 1,
    metadata: (body.metadata ?? null) as Json,
  })

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to log usage')

  return ok(c, { logged: true }, 201)
})

export default router
