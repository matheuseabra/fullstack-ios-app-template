# AGENTS.md

> How AI agents should work on this codebase. Read this before writing any code.

---

## Who Are You?

You are an AI coding agent working on an iOS app built from the **AppStudio Boilerplate**. This repo follows strict conventions — they exist so apps can be shipped fast without accumulating debt. Respect them.

---

## Repo Map

```
ios/          SwiftUI iOS app
backend/      Hono API (Node.js + TypeScript)
supabase/     DB migrations + local config
designs/      Stitch UI design html files
docs/         Architecture docs — read before building
.agents/      You are here
  AGENTS.md             This file
  workflows/            Step-by-step task playbooks
  tools/                Executable scripts you can run
```

**Always read `docs/` before building a new feature.** It contains design decisions that took time to make. Don't undo them silently.

---

## Non-Negotiables

### Security
- **Never hardcode secrets.** All secrets go in `.env` (backend) or Xcode build config (iOS). Never commit them.
- **Never bypass RLS.** If you need to write to a table for a user, do it via service_role in the backend, not by weakening policies.
- **Never expose `service_role` key to the iOS app.** The iOS app only uses `anon` key via Supabase Auth.
- **Validate every API input with Zod.** No route handler should access `c.req.json()` without a schema.

### Code Style
- **TypeScript strict mode.** No `any`. If you need an escape hatch, use `unknown` + type guard.
- **Run lint before finishing.** `npm run lint` in `backend/`. Fix all errors.
- **SwiftUI: no UIKit unless forced.** Prefer SwiftUI equivalents.
- **No new SPM packages without asking.** Package bloat is real.

### Database
- **Every new table needs RLS.** Copy the RLS block from `docs/DATABASE.md`.
- **Every migration is a new file.** `supabase/migrations/XXXX_description.sql`. Never edit existing migrations.
- **After schema changes:** run `npm run db:types` to regenerate TypeScript types.

### Testing
- **New routes need at least one test.** Happy path + one error case minimum.
- Backend: `tests/[route].test.ts` using Jest + Supertest.

---

## How to Add a New Feature

### Option A — Use a Workflow
Check `.agents/workflows/` first. There may already be a playbook:
- `new-screen.md` — Scaffold a new SwiftUI screen
- `new-api-route.md` — Add a new backend API endpoint
- `new-db-table.md` — Add a new table with RLS

### Option B — Manual Steps

**New SwiftUI Screen:**
1. Create `ios/Screens/[Feature]/[Feature]View.swift`
2. Create `ios/Screens/[Feature]/[Feature]ViewModel.swift`
3. Register in `ios/App/AppRouter.swift`
4. Follow design system in `docs/DESIGN_SYSTEM.md`
5. Add PostHog analytics event for screen view
6. **Add entry to `docs/FEATURES.md`**

**New API Route:**
1. Create `backend/src/routes/[feature].ts`
2. Create `backend/src/schemas/[feature].schema.ts` with Zod
3. Mount in `backend/src/app.ts`
4. Write tests in `backend/tests/[feature].test.ts`
5. Document with OpenAPI JSDoc comment
6. **Add entry to `docs/FEATURES.md`**

**New DB Table:**
1. Write migration in `supabase/migrations/XXXX_[table].sql`
2. Include RLS policies (see `docs/DATABASE.md` for patterns)
3. Run `supabase db push` (never `db reset` on staging/production)
4. Run `npm run db:types` to regenerate types
5. **Add table to `docs/DATABASE.md` → Implemented Feature Tables**
6. **Add entry to `docs/FEATURES.md`**

---

## MCPs Available

### Stitch MCP
Use for UI design exploration before building SwiftUI views.

```
stitch: create_design(prompt: "iOS dark mode [screen name] screen")
stitch: export_png(design_id: "...")      → reference image
stitch: export_html(design_id: "...")     → HTML/CSS reference
```

Then follow the `new-screen.md` workflow to convert to SwiftUI.

### XcodeBuildMCP
Use to build + validate after every SwiftUI change.

```
xcode: build(scheme: "MyApp", destination: "iPhone 16 Pro")
xcode: get_build_errors()
```

**Always run a build before marking a task complete.**

---

## Skills Available

These skill files contain deep expertise. Load them when relevant:

| Skill | When to Use |
|---|---|
| `mobile-ios-design` | Any UI/design decision, component styling, layout |
| `swiftui-expert-skill` | SwiftUI patterns, state management, performance |
| `developing-ios-apps` | Xcode setup, SPM, build issues, iOS APIs |

Skills are loaded via your agent framework. They supplement this guide with deep context.

---

## Tools Available

### Image Generation
Generate app icons, illustrations, and in-app assets.

```bash
node .agents/tools/generate-image.js \
  --prompt "minimal flat illustration of [subject], dark background, [accent color] accent" \
  --output ios/Resources/Assets.xcassets/Illustrations/[name].imageset/
```

See `.agents/tools/generate-image.js` for full usage.

---

## Analytics Contract

Every user-facing screen and key interaction must fire a PostHog event. This is not optional.

```swift
// Screen views
Analytics.track(.screenViewed("onboarding_step_2"))

// Key actions
Analytics.track(.featureUsed("task_completed"))
Analytics.track(.paywallViewed(screen: 1))
```

Backend equivalents use `src/services/posthog.ts`.

---

## Commit Style

```
feat(ios): add paywall trial explainer screen
fix(backend): correct rate limit window calculation
chore(db): add usage_logs table migration
docs: update onboarding flow diagram
```

---

## Definition of Done

A task is done when:
- [ ] Code compiles with no errors (`xcode: build` passes)
- [ ] Lint passes (`npm run lint`)
- [ ] Tests pass (`npm test`)
- [ ] Analytics event fires for any new user action
- [ ] RLS policies exist for any new DB table
- [ ] `.env.example` updated if new env vars added
- [ ] **Docs updated** — see Documentation Rule below

---

## Documentation Rule

> **Every feature implementation must update the docs. This is not optional.**

After implementing any feature:

| What changed | What to update |
|---|---|
| New DB table | Add to **`docs/DATABASE.md`** under "Implemented Feature Tables" |
| New feature (any size) | Add to **`docs/FEATURES.md`** feature registry |
| New phase / set of tasks | Add a Phase to **`docs/ROLLOUT_PLAN.md`** with all steps checked |
| New architectural decision | Add an ADR to **`docs/ARCHITECTURE.md`** |
| New agent workflow | Add a file to **`.agents/workflows/`** |

### Template — New Feature Entry in `docs/FEATURES.md`

```markdown
## [Feature Name]

**Status:** ✅ Implemented / 🚧 In Progress / 📋 Planned
**Migration:** `supabase/migrations/XXXX_[name].sql` (or N/A)
**iOS screens:** `Screens/[Feature]/`
**Backend routes:** `backend/src/routes/[feature].ts` (or N/A)

### What it does
One paragraph describing the user-facing functionality.

### Key files
- `ios/Models/[Model].swift` — SwiftData model
- `ios/Screens/[Feature]/[Feature]View.swift` — main view
- `backend/src/routes/[feature].ts` — REST endpoints
- `supabase/migrations/XXXX_[name].sql` — DB schema

### Analytics events
- `featureUsed("[action]")` — fired on [X]
```
