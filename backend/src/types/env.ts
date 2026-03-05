import dotenv from 'dotenv'
import { z } from 'zod'

dotenv.config()

const boolFlag = (defaultValue: boolean) =>
  z.string().optional()
    .transform((v) => v === undefined ? defaultValue : v.toLowerCase() !== 'false')

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3000),
  ALLOWED_ORIGINS: z.string().default('http://localhost:3000'),

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

  // Feature flags — all default to true; set "false" to disable a module
  ENABLE_ONBOARDING: boolFlag(true),
  ENABLE_SUBSCRIPTIONS: boolFlag(true),
  ENABLE_NOTIFICATIONS: boolFlag(true),
  ENABLE_USAGE_TRACKING: boolFlag(true),
})

export type Env = z.infer<typeof envSchema>

function parseEnv(): Env {
  const result = envSchema.safeParse(process.env)
  if (!result.success) {
    console.error('Invalid environment variables:')
    for (const [field, errors] of Object.entries(result.error.flatten().fieldErrors)) {
      console.error(`  ${field}: ${errors?.join(', ')}`)
    }
    process.exit(1)
  }
  return result.data
}

export const env = parseEnv()
