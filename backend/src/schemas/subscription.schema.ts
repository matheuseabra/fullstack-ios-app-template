import { z } from 'zod'

// RevenueCat webhook event types we handle
export const revenueCatEventTypes = [
  'INITIAL_PURCHASE',
  'RENEWAL',
  'CANCELLATION',
  'UNCANCELLATION',
  'EXPIRATION',
  'BILLING_ISSUE',
  'PRODUCT_CHANGE',
  'TRIAL_STARTED',
  'TRIAL_CONVERTED',
  'TRIAL_CANCELLED',
  'TRANSFER',
] as const

export const revenueCatWebhookSchema = z.object({
  event: z.object({
    type: z.string(),
    app_user_id: z.string(),
    original_app_user_id: z.string().optional(),
    product_id: z.string().optional(),
    period_type: z.string().optional(),
    purchased_at_ms: z.number().optional(),
    expiration_at_ms: z.number().optional(),
    cancel_reason: z.string().optional(),
    entitlement_ids: z.array(z.string()).optional(),
  }),
})

export type RevenueCatWebhookInput = z.infer<typeof revenueCatWebhookSchema>
