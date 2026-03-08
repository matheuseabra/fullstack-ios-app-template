import { env } from '../types/env.js'
import { logger } from '../lib/logger.js'

interface CaptureEventOptions {
  distinctId: string
  event: string
  properties?: Record<string, unknown>
}

// Lightweight PostHog server-side capture via REST API.
// Fires-and-forgets — never blocks the request path.
export async function captureEvent({
  distinctId,
  event,
  properties = {},
}: CaptureEventOptions): Promise<void> {
  if (!env.POSTHOG_API_KEY) return

  try {
    const res = await fetch(`${env.POSTHOG_HOST}/capture/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        api_key: env.POSTHOG_API_KEY,
        event,
        distinct_id: distinctId,
        properties: { ...properties, $lib: 'backend' },
        timestamp: new Date().toISOString(),
      }),
    })
    if (!res.ok) {
      const body = await res.text().catch(() => '')
      logger.warn({ status: res.status, body, event }, 'PostHog capture rejected')
    }
  } catch (err) {
    // Non-fatal — analytics failure must never break the request
    logger.warn({ err, event }, 'PostHog capture failed')
  }
}

export const posthog = { captureEvent }
