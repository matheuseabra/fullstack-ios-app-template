import { createMiddleware } from 'hono/factory'
import { redis, memoryStore } from '../services/redis.js'
import { AppError } from '../lib/errors.js'

interface RateLimitOptions {
  requests: number
  window: '1m' | '5m' | '15m' | '1h' | '1d'
}

const WINDOW_SECONDS: Record<RateLimitOptions['window'], number> = {
  '1m': 60,
  '5m': 300,
  '15m': 900,
  '1h': 3600,
  '1d': 86400,
}

export const rateLimiter = (opts: RateLimitOptions) =>
  createMiddleware(async (c, next) => {
    // Use userId for authenticated routes, fallback to IP for public routes
    const userId =
      (c.get('userId') as string | undefined) ??
      c.req.header('x-forwarded-for') ??
      'anon'
    const key = `ratelimit:${userId}:${c.req.path}`
    const windowSeconds = WINDOW_SECONDS[opts.window]

    let count: number

    if (redis) {
      // Redis path — atomic INCR + EXPIRE on first hit
      count = await redis.incr(key)
      if (count === 1) await redis.expire(key, windowSeconds)
    } else {
      // In-memory fallback
      const now = Date.now()
      const entry = memoryStore.get(key)

      if (!entry || entry.expiresAt < now) {
        memoryStore.set(key, { count: 1, expiresAt: now + windowSeconds * 1000 })
        count = 1
      } else {
        entry.count += 1
        count = entry.count
      }
    }

    c.header('X-RateLimit-Limit', String(opts.requests))
    c.header('X-RateLimit-Remaining', String(Math.max(0, opts.requests - count)))

    if (count > opts.requests) {
      throw new AppError(429, 'RATE_LIMITED', 'Too many requests — please slow down')
    }

    await next()
  })
