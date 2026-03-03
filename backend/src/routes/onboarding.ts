// Route: /api/onboarding — quiz responses
import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import type { AppEnv } from '../types/index.js'
import { supabaseService } from '../services/supabase.js'
import { ok } from '../lib/response.js'
import { AppError } from '../lib/errors.js'
import { submitOnboardingResponsesSchema } from '../schemas/onboarding.schema.js'
import type { Json } from '../types/database.js'

const router = new Hono<AppEnv>()

// POST /api/onboarding/responses — save quiz answers (batch, idempotent upsert)
router.post('/responses', zValidator('json', submitOnboardingResponsesSchema), async (c) => {
  const userId = c.get('userId')
  const { responses } = c.req.valid('json')

  const rows = responses.map(({ question_key, answer }) => ({
    user_id: userId,
    question_key,
    answer: answer as Json,
  }))

  const { data, error } = await supabaseService
    .from('onboarding_responses')
    .upsert(rows, { onConflict: 'user_id,question_key' })
    .select('question_key, answer, created_at')

  if (error) throw new AppError(500, 'INTERNAL_ERROR', 'Failed to save onboarding responses')

  return ok(c, { saved: data?.length ?? rows.length }, 201)
})

export default router
