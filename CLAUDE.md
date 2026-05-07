# FieldOps — Claude Code Brain

## Project overview

Single-page HTML + JS field marketing management app. No build step, no framework — everything lives in `index.html`. Backend is a Supabase (PostgreSQL) project. Hosted on GitHub Pages.

## Files

```
FieldOps/
├── index.html   — entire app: HTML, CSS, JS in one file
├── schema.sql   — run once in Supabase SQL Editor to create tables + seed data
├── README.md    — setup guide for non-technical users
└── vault/       — decisions, error logs, patterns, session notes, schema snapshots
```

## Stack

| Layer | Technology |
|---|---|
| Frontend | Vanilla JS, Tabler Icons (CDN) |
| Backend | Supabase (PostgreSQL + RLS) |
| Auth | None — credentials stored in localStorage |
| Hosting | GitHub Pages |
| CDN deps | `@supabase/supabase-js@2`, `@tabler/icons-webfont@2.44.0` |

## Database tables

| Table | Purpose |
|---|---|
| `events` | Demo events — schedule, status, results |
| `ambassadors` | Brand ambassador roster, ratings, pay rates |
| `reports` | Post-event reports with approval workflow |
| `payments` | Ambassador pay tracking (pending → approved → paid) |
| `stores` | Retailer location directory |
| `surveys` | Shopper feedback per event |

All tables use RLS with a permissive `"Public access"` policy (no auth layer).

## App modules

Dashboard · Events · Ambassadors · Reports · Payments · Analytics · Surveys · Store Directory

## Git workflow (always follow)

1. **Branch** — `git checkout -b <type>/<short-description>` before any change
2. **Commit atomically** — one logical change per commit, present-tense message
3. **Push + PR** — `git push -u origin <branch>` then `gh pr create`
4. Never commit directly to `main`

Branch naming: `feat/`, `fix/`, `refactor/`, `docs/`, `setup/`

## Supabase notes

- Credentials are entered by each user at first launch and stored in `localStorage`
- `resetConfig()` in the browser console clears stored credentials
- RLS is enabled on all tables; current policy allows full public access

## Vault

`vault/` is a structured knowledge store for this project:

- `decisions/` — architectural and product decisions (ADRs)
- `errors/` — bugs encountered and how they were fixed
- `patterns/` — reusable code snippets and UI patterns specific to this app
- `sessions/` — session summaries of significant work
- `schema/` — point-in-time schema snapshots

## Development notes

- No local dev server needed — open `index.html` directly in a browser
- All JS is inline; search for `// ──` section headers to navigate
- Dark mode supported via `prefers-color-scheme` CSS media query
- CSS variables defined in `:root` — use them for any new UI work
