# Workflow: Add a New API Route

**Trigger:** Agent asked to add a new backend endpoint.

---

## Steps

### 1. Define the Schema First

Create the Zod schema before writing any handler logic.

```typescript
// backend/src/schemas/[feature].schema.ts
import { z } from 'zod'

export const CreateFeatureSchema = z.object({
  title: z.string().min(1).max(255),
  metadata: z.record(z.unknown()).optional(),
})

export type CreateFeatureInput = z.infer<typeof CreateFeatureSchema>
```

### 2. Create the Route File

```typescript
// backend/src/routes/[feature].ts
import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import { supabaseService } from '../services/supabase'
import { usageCap } from '../middleware/usageCap'
import { ok, created, notFound } from '../lib/response'
import { CreateFeatureSchema } from '../schemas/[feature].schema'

const app = new Hono()

/**
 * @openapi
 * /api/[feature]:
 *   get:
 *     summary: List user's [feature] items
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200:
 *         description: Success
 */
app.get('/', async (c) => {
  const userId = c.get('userId')

  const { data, error } = await supabaseService
    .from('[table]')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })

  if (error) throw error
  return ok(c, data)
})

/**
 * @openapi
 * /api/[feature]:
 *   post:
 *     summary: Create a [feature] item
 */
app.post('/',
  usageCap({ feature: '[feature]', freeTierLimit: 10, paidTierLimit: 'unlimited' }),
  zValidator('json', CreateFeatureSchema),
  async (c) => {
    const userId = c.get('userId')
    const body = c.req.valid('json')

    const { data, error } = await supabaseService
      .from('[table]')
      .insert({ ...body, user_id: userId })
      .select()
      .single()

    if (error) throw error
    return created(c, data)
  }
)

export default app
```

### 3. Mount in app.ts

```typescript
// backend/src/app.ts
import featureRoutes from './routes/[feature]'

app.route('/api/[feature]', featureRoutes)
```

### 4. Write Tests

```typescript
// backend/tests/[feature].test.ts
import { testApp } from './setup'
import { mockUser } from './fixtures'

describe('GET /api/[feature]', () => {
  it('returns empty array for new user', async () => {
    const res = await testApp.request('/api/[feature]', {
      headers: { Authorization: `Bearer ${mockUser.token}` }
    })
    expect(res.status).toBe(200)
    const body = await res.json()
    expect(body.data).toEqual([])
  })

  it('returns 401 without auth', async () => {
    const res = await testApp.request('/api/[feature]')
    expect(res.status).toBe(401)
  })
})
```

### 5. Verify

```bash
npm run lint
npm test -- [feature]
```

---

## Checklist

- [ ] Zod schema defined before handler
- [ ] Input validated with `zValidator`
- [ ] `usageCap` middleware applied to AI/expensive operations
- [ ] OpenAPI JSDoc comment added
- [ ] Route mounted in `app.ts`
- [ ] Tests written (happy path + 401)
- [ ] Lint passes
