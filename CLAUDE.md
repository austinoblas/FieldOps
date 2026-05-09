# CLAUDE.md — FieldOps
> Read this at the start of every session.

## Project
- App: FieldOps — Field Marketing Platform
- Stack: Vanilla HTML/CSS/JS (single-file), Supabase, Chart.js, Tabler Icons
- Hosting: GitHub Pages
- Files: index.html (entire app), schema.sql (run once in Supabase), README.md

## Rules
1. Never mass-edit more than 2 major sections without showing a plan first
2. Always use str_replace / targeted edits — never rewrite the full file
3. Test dark mode for any CSS change
4. Preserve the existing CSS variable system
5. No new CDN dependencies without approval
6. Schema changes require ALTER TABLE SQL — never just edit schema.sql
7. If a task needs 4+ file changes, write a plan first and wait for approval

## Conventions
- State lives in S = { events, ambassadors, reports, payments, stores, surveys, view, filters, charts }
- Views return HTML strings rendered via document.getElementById("main").innerHTML
- Every view: [viewName]View() — e.g. dashboardView(), eventsView()
- Supabase calls: always showLoading() / hideLoading() + check { error }
- Toast: toast("message", "ok" | "err")
- Commits: feat:, fix:, chore:, style:, refactor:, docs:

## Supabase Tables
events       id, name, store, store_address, retailer, date, time, status, ambassador, ambassador_id, accepted, product, hourly_rate, budget, notes, units_sold, samples, sales_lift
ambassadors  id, name, email, phone, status, events_month, total_events, rating, specialty, rate, city
reports      id, event_name, ambassador, date, status, units_sold, samples, feedback, photos, sales_lift
payments     id, ambassador, event_name, date, hours, rate, expenses, total, status
stores       id, name, retailer, address, manager, phone, priority, last_demo, total_demos
surveys      id, event_name, responses, rating, top_feedback, date

## Current Focus
- [ ] Update this each session

## Session Log
| Date | What happened | Files changed |
|------|---------------|---------------|
| 2026-05-09 | Fixed schema mismatch (hourly_rate, store_address); added Supabase Realtime with debounced silent refresh; cleaned up rtChannel on sign-out | index.html, CLAUDE.md, schema (ALTER TABLE) |
| -    | Project setup | CLAUDE.md     |

## Backlog
| Idea | Priority |
|------|----------|
| Supabase Auth | High |
| Photo uploads on reports | Medium |
| CSV export for payments | Medium |
| Mobile sidebar | Medium |
| Search/filter bar | Medium |
