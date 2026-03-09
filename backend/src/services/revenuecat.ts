import { timingSafeEqual } from 'crypto'
import { env } from '../types/env.js'
import { logger } from '../lib/logger.js'

export function validateRevenueCatSignature(
  _body: string,
  authorization: string | undefined,
): boolean {
  const secret = env.REVENUECAT_WEBHOOK_SECRET

  if (!secret) {
    if (env.NODE_ENV !== 'production') {
      logger.warn('REVENUECAT_WEBHOOK_SECRET not configured — skipping webhook auth in non-production')
      return true
    }

    logger.error('REVENUECAT_WEBHOOK_SECRET missing in production')
    return false
  }

  if (secret.startsWith('your_')) {
    logger.error('REVENUECAT_WEBHOOK_SECRET is still using a template placeholder')
    return false
  }

  if (!authorization) return false

  try {
    const expected = `Bearer ${secret}`
    if (authorization.length !== expected.length) return false
    return timingSafeEqual(Buffer.from(authorization), Buffer.from(expected))
  } catch (err) {
    logger.warn({ err }, 'RevenueCat signature validation error')
    return false
  }
}

export async function getRevenueCatSubscriber(appUserId: string): Promise<unknown | null> {
  if (!env.REVENUECAT_API_KEY) return null

  const res = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`,
    {
      headers: {
        Authorization: `Bearer ${env.REVENUECAT_API_KEY}`,
        'Content-Type': 'application/json',
      },
    },
  )

  if (!res.ok) {
    logger.warn({ status: res.status, appUserId }, 'RevenueCat subscriber fetch failed')
    return null
  }

  return res.json()
}
