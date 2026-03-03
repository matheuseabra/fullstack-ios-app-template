import { z } from 'zod'

export const logUsageSchema = z.object({
  metadata: z.record(z.unknown()).optional(),
})

export type LogUsageInput = z.infer<typeof logUsageSchema>
