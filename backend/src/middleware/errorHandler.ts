import type { Context } from 'hono'
import { AppError } from '../lib/errors.js'
import { logger } from '../lib/logger.js'

export function errorHandler(err: Error, c: Context): Response {
  // Known app error — return structured JSON with our error code
  if (err instanceof AppError) {
    return c.json(
      { error: { code: err.code, message: err.message }, ok: false },
      err.status as never,
    )
  }

  // Hono HTTPException — has a status property
  if ('status' in err && typeof (err as { status: unknown }).status === 'number') {
    const status = (err as { status: number }).status
    return c.json(
      { error: { code: 'HTTP_ERROR', message: err.message }, ok: false },
      status as never,
    )
  }

  // Unexpected errors — log full details, return generic 500
  logger.error({ err }, 'Unhandled server error')
  return c.json(
    { error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' }, ok: false },
    500,
  )
}
