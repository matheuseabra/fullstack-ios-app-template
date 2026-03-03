import { createMiddleware } from 'hono/factory'
import { supabaseService } from '../services/supabase.js'
import { AppError } from '../lib/errors.js'

interface UsageCapOptions {
  feature: string
  freeTierLimit: number
  paidTierLimit: number | 'unlimited'
}

// Apply per-user daily feature caps based on subscription tier.
// Usage: app.post('/api/ai/generate', usageCap({ feature: 'ai_generation', freeTierLimit: 5, paidTierLimit: 100 }), handler)
export const usageCap = (opts: UsageCapOptions) =>
  createMiddleware(async (c, next) => {
    const userId = c.get('userId') as string

    // Determine subscription tier
    const { data: sub } = await supabaseService
      .from('subscriptions')
      .select('status')
      .eq('user_id', userId)
      .maybeSingle()

    const isPaid = ['trial', 'active'].includes(sub?.status ?? '')
    const limit = isPaid ? opts.paidTierLimit : opts.freeTierLimit

    if (limit !== 'unlimited') {
      // Count usage since start of today (UTC)
      const todayStart = new Date()
      todayStart.setUTCHours(0, 0, 0, 0)

      const { count } = await supabaseService
        .from('usage_logs')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('feature', opts.feature)
        .gte('created_at', todayStart.toISOString())

      if ((count ?? 0) >= limit) {
        throw new AppError(
          403,
          'USAGE_LIMIT_REACHED',
          `Daily limit of ${limit} reached for ${opts.feature}`,
        )
      }
    }

    await next()
  })
