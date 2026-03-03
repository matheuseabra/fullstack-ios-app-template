import { z } from 'zod'

export const registerTokenSchema = z.object({
  push_token: z.string().min(1).max(512),
})

export type RegisterTokenInput = z.infer<typeof registerTokenSchema>

export const updatePreferencesSchema = z.object({
  enabled: z.boolean().optional(),
  reminder_time: z
    .string()
    .regex(/^\d{2}:\d{2}$/, 'Must be HH:MM format')
    .optional(),
  days_of_week: z.array(z.number().int().min(0).max(6)).optional(),
})

export type UpdatePreferencesInput = z.infer<typeof updatePreferencesSchema>
