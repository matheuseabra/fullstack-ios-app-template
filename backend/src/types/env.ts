import dotenv from 'dotenv'
import { z } from 'zod'

dotenv.config()

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3000),
  ALLOWED_ORIGINS: z.string().optional(),

  SUPABASE_URL: z.string().min(1),
  SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),

  REVENUECAT_WEBHOOK_SECRET: z.string().optional(),
  REVENUECAT_API_KEY: z.string().optional(),

  POSTHOG_API_KEY: z.string().optional(),
  POSTHOG_HOST: z.string().default('https://app.posthog.com'),

  REDIS_URL: z.string().optional(),

  R2_ACCOUNT_ID: z.string().optional(),
  R2_ACCESS_KEY_ID: z.string().optional(),
  R2_SECRET_ACCESS_KEY: z.string().optional(),
  R2_BUCKET_NAME: z.string().optional(),
  R2_PUBLIC_URL: z.string().optional(),
})

export type Env = Omit<z.infer<typeof envSchema>, 'ALLOWED_ORIGINS'> & {
  ALLOWED_ORIGINS: string
}

function printEnvError(field: string, message: string) {
  console.error(`  ${field}: ${message}`)
}

function parseEnv(): Env {
  const result = envSchema.safeParse(process.env)
  if (!result.success) {
    console.error('Invalid environment variables:')
    for (const [field, errors] of Object.entries(result.error.flatten().fieldErrors)) {
      console.error(`  ${field}: ${errors?.join(', ')}`)
    }
    process.exit(1)
  }

  const data = result.data
  const allowedOrigins = data.ALLOWED_ORIGINS?.trim()
  const webhookSecret = data.REVENUECAT_WEBHOOK_SECRET?.trim()

  const productionErrors: Array<[string, string]> = []

  if (data.NODE_ENV === 'production') {
    if (!allowedOrigins) {
      productionErrors.push(['ALLOWED_ORIGINS', 'required in production'])
    } else if (allowedOrigins.split(',').some((origin) => origin.trim() === '*')) {
      productionErrors.push(['ALLOWED_ORIGINS', 'wildcard origins are not allowed in production'])
    }

    if (!webhookSecret) {
      productionErrors.push([
        'REVENUECAT_WEBHOOK_SECRET',
        'required in production to validate RevenueCat webhooks',
      ])
    } else if (webhookSecret.startsWith('your_')) {
      productionErrors.push([
        'REVENUECAT_WEBHOOK_SECRET',
        'must be a real secret, not a template placeholder',
      ])
    }
  }

  if (productionErrors.length > 0) {
    console.error('Invalid environment variables:')
    for (const [field, message] of productionErrors) {
      printEnvError(field, message)
    }
    process.exit(1)
  }

  return {
    ...data,
    ALLOWED_ORIGINS: allowedOrigins || 'http://localhost:3000',
    REVENUECAT_WEBHOOK_SECRET: webhookSecret,
  }
}

export const env = parseEnv()
