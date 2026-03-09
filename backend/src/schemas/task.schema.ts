import { z } from 'zod'

export const repeatFrequencySchema = z.enum(['daily', 'weekly', 'monthly', 'yearly'])
const categoryIdSchema = z.string().uuid()

export const createTaskSchema = z.object({
  title: z.string().min(1).max(500),
  note: z.string().max(2000).optional().default(''),
  is_completed: z.boolean().optional().default(false),
  priority: z.enum(['low', 'medium', 'high']).optional().default('medium'),
  due_date: z.string().datetime().nullable().optional(),
  completed_at: z.string().datetime().nullable().optional(),
  category_id: categoryIdSchema.nullable().optional(),
  repeat_frequency: repeatFrequencySchema.nullable().optional(),
}).superRefine((value, ctx) => {
  if (value.repeat_frequency && !value.due_date) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'Recurring tasks require a due_date',
      path: ['due_date'],
    })
  }
})

export const updateTaskSchema = z.object({
  title: z.string().min(1).max(500).optional(),
  note: z.string().max(2000).optional(),
  is_completed: z.boolean().optional(),
  priority: z.enum(['low', 'medium', 'high']).optional(),
  due_date: z.string().datetime().nullable().optional(),
  completed_at: z.string().datetime().nullable().optional(),
  category_id: categoryIdSchema.nullable().optional(),
  repeat_frequency: repeatFrequencySchema.nullable().optional(),
})

export type CreateTaskInput = z.infer<typeof createTaskSchema>
export type UpdateTaskInput = z.infer<typeof updateTaskSchema>
