// CommonJS — keeps this file out of the ESM transform pipeline.
// Sets env vars before any module is loaded so Zod's env.ts schema doesn't fail.
process.env.NODE_ENV = 'test'
process.env.PORT = '3000'
process.env.ALLOWED_ORIGINS = 'http://localhost:3000'
process.env.SUPABASE_URL = 'http://localhost:54321'
process.env.SUPABASE_ANON_KEY = 'test-anon-key'
process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-service-role-key'
