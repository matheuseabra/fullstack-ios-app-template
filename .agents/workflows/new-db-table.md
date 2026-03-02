# Workflow: Add a New Database Table

**Trigger:** Agent asked to add a new table or modify the database schema.

---

## Steps

### 1. Create Migration File

```bash
# Naming: XXXX = next sequential number
# Example: 0004_tasks.sql
touch supabase/migrations/0004_[table_name].sql
```

### 2. Write the Migration

Follow this template — every table needs all sections:

```sql
-- supabase/migrations/XXXX_[table_name].sql

-- ============================================================
-- Table: [table_name]
-- Description: [what this table stores]
-- ============================================================

create table public.[table_name] (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,

  -- Your columns here
  title       text not null,
  data        jsonb,

  -- Always include these
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- Indexes
create index on public.[table_name](user_id);
create index on public.[table_name](created_at);

-- Enable RLS (REQUIRED — no exceptions)
alter table public.[table_name] enable row level security;

-- RLS Policies
-- Users can only access their own rows
create policy "[table_name]: users can select own rows"
  on public.[table_name] for select
  using (auth.uid() = user_id);

create policy "[table_name]: users can insert own rows"
  on public.[table_name] for insert
  with check (auth.uid() = user_id);

create policy "[table_name]: users can update own rows"
  on public.[table_name] for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "[table_name]: users can delete own rows"
  on public.[table_name] for delete
  using (auth.uid() = user_id);

-- Auto-update updated_at
create trigger set_updated_at
  before update on public.[table_name]
  for each row execute function public.set_updated_at();
```

> **Special case — internal tables (subscriptions, audit_log):**  
> If users should NOT write to this table, omit the insert/update/delete policies.  
> The backend uses `service_role` key to write these.

### 3. Apply Migration

```bash
# Local
npx supabase db push

# Verify it applied
npx supabase db diff
```

### 4. Regenerate TypeScript Types

```bash
cd backend && npm run db:types
```

This updates `src/types/database.ts` — commit this file.

### 5. Add to Seed (Optional)

If useful for development, add sample rows to `supabase/seed.sql`:

```sql
-- seed.sql
insert into public.[table_name] (user_id, title)
values
  ('00000000-0000-0000-0000-000000000001', 'Sample item 1'),
  ('00000000-0000-0000-0000-000000000001', 'Sample item 2');
```

---

## RLS Quick Reference

| Scenario | Policy Pattern |
|---|---|
| User owns row | `using (auth.uid() = user_id)` |
| Public read, private write | Select: `using (true)`, Insert/Update/Delete: `using (auth.uid() = user_id)` |
| Admin/service only | No policies — only service_role can access |
| Shared team data | `using (user_id in (select member_id from team_members where team_id = ...))` |

---

## Checklist

- [ ] Migration file named with sequential number
- [ ] Table has `id`, `user_id`, `created_at`, `updated_at`
- [ ] `enable row level security` on the table
- [ ] All four RLS policies (or explicitly skipped with reason)
- [ ] `set_updated_at` trigger added
- [ ] `supabase db push` ran successfully
- [ ] `npm run db:types` ran and `database.ts` updated
