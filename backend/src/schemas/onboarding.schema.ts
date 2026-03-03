import { z } from 'zod'

export const onboardingResponseSchema = z.object({
  question_key: z.string().min(1).max(255),
  answer: z.unknown(),
})

export const submitOnboardingResponsesSchema = z.object({
  responses: z.array(onboardingResponseSchema).min(1).max(50),
})

export type SubmitOnboardingResponsesInput = z.infer<typeof submitOnboardingResponsesSchema>
