import type { Context } from 'hono'

export function ok<T>(c: Context, data: T, status = 200) {
  return c.json({ data, ok: true }, status as never)
}

export function fail(c: Context, code: string, message: string, status = 400) {
  return c.json({ error: { code, message }, ok: false }, status as never)
}
