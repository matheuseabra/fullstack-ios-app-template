import { serve } from '@hono/node-server'
import app from './app.js'
import { env } from './types/env.js'
import { logger } from './lib/logger.js'

serve({ fetch: app.fetch, port: env.PORT }, (info) => {
  logger.info(`Server running on http://localhost:${info.port}`)
  if (env.NODE_ENV === 'development') {
    logger.info(`Swagger UI:  http://localhost:${info.port}/docs`)
    logger.info(`Health:      http://localhost:${info.port}/health`)
  }
})
