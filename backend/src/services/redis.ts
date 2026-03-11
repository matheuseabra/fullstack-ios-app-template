import { Redis } from 'ioredis'
import { env } from '../types/env.js'
import { logger } from '../lib/logger.js'

export let redis: Redis | null = null

export function disableRedis(reason: string) {
  if (redis) {
    logger.warn({ err: reason }, 'Redis disabled — rate limiter falling back to in-memory')
    try {
      redis.disconnect()
    } catch {
      // Ignore disconnect errors
    }
  }
  redis = null
}

if (env.REDIS_URL) {
  redis = new Redis(env.REDIS_URL, {
    lazyConnect: true,
    maxRetriesPerRequest: 2,
    enableOfflineQueue: false,
  })

  redis.on('error', (err: Error) => {
    disableRedis(err.message)
  })

  redis.on('end', () => {
    disableRedis('Connection ended')
  })

  redis.connect().catch((err: Error) => {
    disableRedis(err.message)
  })
}

// In-memory fallback for rate limiting when Redis is not configured
export type MemoryEntry = { count: number; expiresAt: number }
export const memoryStore = new Map<string, MemoryEntry>()
