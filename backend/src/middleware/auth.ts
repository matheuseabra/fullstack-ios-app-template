import { createMiddleware } from 'hono/factory'
import { supabaseService } from '../services/supabase.js'
import { AppError } from '../lib/errors.js'
import type { AppEnv } from '../types/index.js'

export const authMiddleware = createMiddleware<AppEnv>(async (c, next) => {
  const token = c.req.header('Authorization')?.replace('Bearer ', '')

  if (!token) {
    throw new AppError(401, 'UNAUTHORIZED', 'Missing Authorization header')
  }

  const {
    data: { user },
    error,
  } = await supabaseService.auth.getUser(token)

  if (error || !user) {
    throw new AppError(401, 'UNAUTHORIZED', 'Invalid or expired token')
  }

  c.set('user', user)
  c.set('userId', user.id)

  await next()
})
