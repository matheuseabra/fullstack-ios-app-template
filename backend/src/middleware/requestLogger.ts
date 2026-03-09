import { randomUUID } from 'crypto'
import { createMiddleware } from 'hono/factory'
import { logger } from '../lib/logger.js'

export const requestLogger = createMiddleware(async (c, next) => {
  const start = Date.now()
  const requestId = c.req.header('x-request-id')?.trim() || randomUUID()
  const method = c.req.method
  const url = new URL(c.req.url)

  c.header('X-Request-Id', requestId)

  await next()

  const ms = Date.now() - start
  const status = c.res.status
  const level = status >= 500 ? 'error' : status >= 400 ? 'warn' : 'info'
  const userId = c.get('userId') as string | undefined

  logger[level](
    {
      requestId,
      userId,
      method,
      path: url.pathname,
      status,
      ms,
    },
    `${method} ${url.pathname} ${status} ${ms}ms`,
  )
})
