import { createHmac, timingSafeEqual } from 'crypto'
import { env } from '../types/env.js'
import { logger } from '../lib/logger.js'

export function validateRevenueCatSignature(
  body: string,
  signature: string | undefined,
): boolean {
  if (!signature || !env.REVENUECAT_WEBHOOK_SECRET) return false

  try {
    const hmac = createHmac('sha256', env.REVENUECAT_WEBHOOK_SECRET)
    hmac.update(body)
    const expected = hmac.digest('hex')
    // Use timing-safe comparison to prevent timing attacks
    return timingSafeEqual(Buffer.from(signature, 'hex'), Buffer.from(expected, 'hex'))
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
