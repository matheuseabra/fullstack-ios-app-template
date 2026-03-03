import { Redis } from 'ioredis'
import { env } from '../types/env.js'
import { logger } from '../lib/logger.js'

let _redis: Redis | null = null

if (env.REDIS_URL) {
  _redis = new Redis(env.REDIS_URL, {
    lazyConnect: true,
    maxRetriesPerRequest: 2,
    enableOfflineQueue: false,
  })

  _redis.on('error', (err: Error) => {
    logger.warn({ err: err.message }, 'Redis error — rate limiter falling back to in-memory')
    _redis = null
  })
}

// Primary store — null when Redis is unavailable
export const redis = _redis

// In-memory fallback for rate limiting when Redis is not configured
export type MemoryEntry = { count: number; expiresAt: number }
export const memoryStore = new Map<string, MemoryEntry>()
