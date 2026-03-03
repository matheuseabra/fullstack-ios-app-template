import type { User } from '@supabase/supabase-js'

// Variables set on the Hono context by authMiddleware
export type AppVariables = {
  user: User
  userId: string
}

// Hono env type — used when creating the app and typed middleware
export type AppEnv = {
  Variables: AppVariables
}
