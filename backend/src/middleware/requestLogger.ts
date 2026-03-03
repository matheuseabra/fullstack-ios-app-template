import { createMiddleware } from 'hono/factory'
import { logger } from '../lib/logger.js'

export const requestLogger = createMiddleware(async (c, next) => {
  const start = Date.now()
  const method = c.req.method
  const url = c.req.url

  await next()

  const ms = Date.now() - start
  const status = c.res.status
  const level = status >= 500 ? 'error' : status >= 400 ? 'warn' : 'info'

  logger[level]({ method, status, ms }, `${method} ${url} ${status} ${ms}ms`)
})
