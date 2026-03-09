import { z } from 'zod'

export const createTaskCategorySchema = z.object({
  name: z.string().trim().min(1).max(80),
  emoji: z.string().trim().min(1).max(16),
})

export type CreateTaskCategoryInput = z.infer<typeof createTaskCategorySchema>