// Route: /auth — public webhook handlers
import { Hono } from 'hono'
import type { AppEnv } from '../types/index.js'
import { validateRevenueCatSignature } from '../services/revenuecat.js'
import { supabaseService } from '../services/supabase.js'
import { posthog } from '../services/posthog.js'
import { revenueCatWebhookSchema } from '../schemas/subscription.schema.js'
import { AppError } from '../lib/errors.js'
import { logger } from '../lib/logger.js'

const router = new Hono<AppEnv>()

// POST /auth/webhook/revenuecat
// Receives RevenueCat subscription lifecycle events and syncs subscription state.
router.post('/webhook/revenuecat', async (c) => {
  const rawBody = await c.req.text()
  const authorization = c.req.header('Authorization')

  if (!validateRevenueCatSignature(rawBody, authorization)) {
    throw new AppError(401, 'INVALID_SIGNATURE', 'Invalid RevenueCat webhook signature')
  }

  let payload: unknown
  try {
    payload = JSON.parse(rawBody)
  } catch {
    throw new AppError(400, 'BAD_REQUEST', 'Invalid JSON body')
  }

  const parsed = revenueCatWebhookSchema.safeParse(payload)
  if (!parsed.success) {
    throw new AppError(400, 'BAD_REQUEST', 'Invalid webhook payload')
  }

  const { event } = parsed.data
  const appUserId = event.original_app_user_id ?? event.app_user_id

  logger.info({ type: event.type, appUserId }, 'RevenueCat webhook received')

  // Map RevenueCat event type to subscription status
  const statusMap: Record<string, string> = {
    INITIAL_PURCHASE: 'active',
    RENEWAL: 'active',
    TRIAL_STARTED: 'trial',
    TRIAL_CONVERTED: 'active',
    TRIAL_CANCELLED: 'expired',
    CANCELLATION: 'cancelled',
    EXPIRATION: 'expired',
    UNCANCELLATION: 'active',
    BILLING_ISSUE: 'past_due',
    PRODUCT_CHANGE: 'active',
  }

  const newStatus = statusMap[event.type]
  if (!newStatus) {
    // Unknown event type — ack so RevenueCat stops retrying
    return c.json({ received: true }, 200)
  }

  const expiresAt = event.expiration_at_ms
    ? new Date(event.expiration_at_ms).toISOString()
    : null

  const trialEndsAt =
    event.type === 'TRIAL_STARTED' && event.expiration_at_ms
      ? new Date(event.expiration_at_ms).toISOString()
      : null

  const { error } = await supabaseService.from('subscriptions').upsert(
    {
      revenuecat_user_id: appUserId,
      product_id: event.product_id ?? null,
      status: newStatus,
      trial_ends_at: trialEndsAt,
      current_period_end: expiresAt,
      cancel_at_period_end: event.type === 'CANCELLATION',
      entitlements: event.entitlement_ids ? { ids: event.entitlement_ids } : null,
    },
    { onConflict: 'revenuecat_user_id' },
  )

  if (error) {
    logger.error({ error, appUserId, type: event.type }, 'Failed to upsert subscription')
    throw new AppError(500, 'INTERNAL_ERROR', 'Failed to process webhook')
  }

  // Fire-and-forget analytics
  void posthog.captureEvent({
    distinctId: appUserId,
    event: `subscription_${event.type.toLowerCase()}`,
    properties: {
      product_id: event.product_id,
      status: newStatus,
      entitlement_ids: event.entitlement_ids,
    },
  })

  return c.json({ received: true }, 200)
})

export default router
