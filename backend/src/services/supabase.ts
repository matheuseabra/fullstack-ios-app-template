import { createClient } from '@supabase/supabase-js'
import type { Database } from '../types/database.js'
import { env } from '../types/env.js'

// Anon client — respects Row Level Security. Use for user-context operations.
export const supabase = createClient<Database>(env.SUPABASE_URL, env.SUPABASE_ANON_KEY)

// Service role client — bypasses RLS. Use only in webhook handlers / admin ops.
// Never expose this client's token to users.
export const supabaseService = createClient<Database>(
  env.SUPABASE_URL,
  env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  },
)

// Create a user-scoped client from a JWT token (authenticates RLS as that user)
export function createUserClient(token: string) {
  return createClient<Database>(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { autoRefreshToken: false, persistSession: false },
  })
}
