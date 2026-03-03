import { z } from 'zod'

export const updateProfileSchema = z.object({
  full_name: z.string().min(1).max(255).optional(),
  avatar_url: z.string().url().optional(),
  timezone: z.string().max(100).optional(),
  locale: z.string().max(20).optional(),
})

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>

export const upsertSettingSchema = z.object({
  key: z.string().min(1).max(255),
  value: z.unknown(),
})

export type UpsertSettingInput = z.infer<typeof upsertSettingSchema>
