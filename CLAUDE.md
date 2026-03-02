# Claude Project Configuration

> Project-scoped settings for Claude agents working on this repo.

---

## Skills

These skills are active for all Claude sessions in this project:

```yaml
skills:
  - https://skills.sh/wshobson/agents/mobile-ios-design
  - https://skills.sh/avdlee/swiftui-agent-skill/swiftui-expert-skill
  - https://skills.sh/daymade/claude-code-skills/developing-ios-apps
```

**When to use each:**
- `mobile-ios-design` → Any screen design, component layout, visual decision
- `swiftui-expert-skill` → SwiftUI patterns, performance, state management, animations
- `developing-ios-apps` → Xcode config, SPM packages, build errors, iOS framework APIs

---

## MCPs

```yaml
mcps:
  stitch:
    description: Google Stitch for UI design exploration and export
    use_for:
      - Exploring design concepts before building screens
      - Exporting PNG + HTML reference for SwiftUI conversion
      - Iterating on layout and visual hierarchy

  xcodebuildmcp:
    description: Build, run, and validate Xcode projects
    use_for:
      - Building the app after SwiftUI changes
      - Catching compile errors before marking tasks done
      - Running on simulator to verify UI
```

---

## Workflows

Always check `.agents/workflows/` before starting a new task:

| Task | Workflow |
|---|---|
| Build a new screen | `.agents/workflows/new-screen.md` |
| Add an API endpoint | `.agents/workflows/new-api-route.md` |
| Add a DB table | `.agents/workflows/new-db-table.md` |

---

## Tools

```yaml
tools:
  generate-image:
    script: .agents/tools/generate-image.js
    description: Generate icons and illustrations via Fal.ai nano-banana-2
    usage: node .agents/tools/generate-image.js --prompt "..." --output path.png
    env_required: FAL_API_KEY
```

---

## Agent Behavior

1. **Always read `AGENTS.md` first** on a new session
2. **Use Stitch before writing any SwiftUI** — design first, code second
3. **Build after every screen change** — `xcode: build` before marking done
4. **Security is non-negotiable** — RLS on every table, Zod on every route

---

## Key Docs

```
docs/DATABASE.md       → DB schema, RLS patterns, migration guide
docs/DESIGN_SYSTEM.md  → Colors, typography, components, spacing
docs/ARCHITECTURE.md   → Why we made the choices we made
ios/README.md          → iOS setup, folder structure, screen specs
backend/README.md      → API setup, middleware, deployment
```
