# 🏗️ AppStudio Boilerplate

> A fullstack mobile app boilerplate for rapidly shipping iOS apps as a studio. One codebase pattern, infinite niches.

## Philosophy

**Build once, ship many.** This boilerplate solves the 80% that every app shares — auth, payments, onboarding, analytics, settings — so you spend 100% of your time on the 20% that makes each app unique.

Every app built from this template is:
- **Local-first** — works offline, syncs in background
- **Monetized from day one** — RevenueCat paywall wired up
- **Observable** — PostHog analytics on every key action
- **Secure by default** — RLS on every table, JWT on every route

---

## What's Inside

```
appstudio-boilerplate/
├── ios/                        # SwiftUI iOS app
├── backend/                    # Hono API (Node.js + TypeScript)
├── supabase/                   # DB migrations + seed + config
├── docs/                       # Architecture, decisions, guides
├── .agents/                    # AI agent instructions + workflows
│   ├── AGENTS.md               # How agents should work on this repo
│   ├── workflows/              # Step-by-step agent workflows
│   └── tools/                  # Agent-usable scripts (image gen, etc.)
├── .github/
│   └── workflows/              # CI pipelines
├── docker-compose.yml          # Local dev stack
├── docker-compose.prod.yml     # Production stack
└── README.md                   # This file
```

---

## Quick Start

### Prerequisites
- Xcode 16+
- Node.js 20+
- Docker + Docker Compose
- Supabase CLI
- Fly.io CLI (`flyctl`)

### 1. Clone & Install
```bash
git clone https://github.com/your-studio/appstudio-boilerplate my-app
cd my-app

# Backend
cd backend && npm install

# iOS — open in Xcode
open ios/MyApp.xcodeproj
```

### 2. Start Local Stack
```bash
# Starts Supabase + Redis (optional) locally
docker-compose up -d

# Run DB migrations
npx supabase db push
```

### 3. Configure Environment
```bash
cp backend/.env.example backend/.env
# Fill in values — see backend/README.md
```

### 4. Run Backend
```bash
cd backend && npm run dev
```

### 5. Run iOS App
Open `ios/` in Xcode, select simulator, ⌘R.

---

## Stack at a Glance

| Layer | Tech | Why |
|---|---|---|
| iOS | SwiftUI + SPM | Native, modern, no RN overhead |
| API | Hono + TypeScript | Tiny, fast, edge-ready |
| Database | Supabase (Postgres) | OSS, free tier, auth built-in |
| Auth | Supabase Auth | Social login + JWT out of the box |
| Payments | RevenueCat | Best-in-class, free up to $2.5k MRR |
| Analytics | PostHog | OSS, self-hostable, generous free tier |
| Storage | Cloudflare R2 | Zero egress fees, S3-compatible |
| Cache | Redis (Docker) | Opt-in, for rate limiting + sessions |
| Deploy | Fly.io | Free hobby tier, global edge |

---

## Monorepo Structure

Both iOS app and backend live in the same repo for:
- Atomic commits across stack
- Shared type definitions (via codegen)
- Single CI pipeline
- Easier agent context

---

## Apps Built With This

| App | Niche | Status |
|---|---|---|
| _Your app here_ | — | — |

---

## Docs

- [Frontend Setup →](ios/README.md)
- [Backend Setup →](backend/README.md)
- [Environments (Dev + Prod) →](docs/ENVIRONMENTS.md)
- [Database Schema →](docs/DATABASE.md)
- [UI Design System →](docs/DESIGN_SYSTEM.md)
- [Agent Guide →](.agents/AGENTS.md)
- [Architecture Decisions →](docs/ARCHITECTURE.md)
