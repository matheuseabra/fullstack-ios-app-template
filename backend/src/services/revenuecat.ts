import { timingSafeEqual } from 'crypto'
import { env } from '../types/env.js'
import { logger } from '../lib/logger.js'

export function validateRevenueCatSignature(
  _body: string,
  authorization: string | undefined,
): boolean {
  const secret = env.REVENUECAT_WEBHOOK_SECRET

  // Skip validation when no real secret is configured
  if (!secret || secret.startsWith('your_')) {
    logger.warn('REVENUECAT_WEBHOOK_SECRET not configured — skipping webhook auth')
    return true
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
