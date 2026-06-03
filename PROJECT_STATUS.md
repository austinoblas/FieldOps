# FieldOps — Project Status

_Last updated: 2026-06-03_

A field-marketing platform for managing brand-ambassador demos, reports, payments, and store relationships. Two clients (web admin + native iOS ambassador app) over one Supabase backend.

## Links

| Resource | URL |
|---|---|
| **Live web app** | https://austinoblas.github.io/FieldOps/ |
| GitHub repo | https://github.com/austinoblas/FieldOps |
| Hosting | GitHub Pages (`main` / root), free |
| Backend | Supabase (project `jlzgpcrrwkcutpqjntku`) |

## Stack

- **Web:** single-file vanilla HTML/CSS/JS (`index.html`, ~130 KB), Chart.js + Tabler Icons via CDN, dark-mode aware. State object `S = { events, ambassadors, reports, payments, stores, surveys, view, filters, charts }`. Views render HTML strings into `#main`.
- **iOS:** `FieldOpsAmbassador/` — SwiftUI, iOS 17+, supabase-swift 2.x. XcodeGen-managed (`project.yml` → `.xcodeproj`). Bundle `com.austinoblas.fieldopsambassador`, team `WM7SVC59JB`.
- **Backend:** Supabase Postgres + Row-Level Security. Tables: `profiles, events, ambassadors, reports, payments, stores, surveys`. Role helper `get_my_role()`, `handle_new_user` trigger auto-creates a profile (default role `ambassador`) on signup.

Status legend: ✅ done · 🟡 partial · 🔴 not started · ⏳ planned next

---

## Web app — features

### Manager-facing
| Feature | Status | Notes |
|---|---|---|
| Dashboard (KPIs, upcoming events, pending actions) | ✅ | `dashboardView()` |
| Events (schedule / track / complete demos) | ✅ | `eventsView()` |
| Ambassadors (roster, ratings, assignment) | ✅ | `ambassadorsView()` |
| Reports (post-event, approval workflow) | ✅ | `reportsView()` |
| Payments (log / approve / pay) | ✅ | `paymentsView()` |
| Analytics (sales-lift charts, retailer breakdown) | ✅ | `analyticsView()`, Chart.js |
| Surveys (shopper feedback) | ✅ | `surveysView()` |
| Store directory (retailers, manager contacts) | ✅ | `storesView()` |

### Ambassador-facing (web)
| Feature | Status | Notes |
|---|---|---|
| My Schedule | ✅ | `scheduleView()` |
| Request an event | ✅ | `requestView()` |
| My Reports | ✅ | `myReportsView()` |
| My Payments | ✅ | `myPaymentsView()` |
| Team | ✅ | `teamView()` |

### Web infrastructure
| Item | Status |
|---|---|
| Supabase Realtime (debounced silent refresh, cleaned up on sign-out) | ✅ |
| Dark mode + CSS variable system | ✅ |
| Per-device config (paste URL + anon key, stored in `localStorage`) | ✅ |

### Web known gaps / backlog
| Item | Priority |
|---|---|
| **Real authentication** — web currently uses a paste-the-anon-key + self-declared name/role model. No login; role is not enforced server-side on the web client. | 🔴 High |
| Photo uploads on reports | 🟡 Medium |
| CSV export for payments | 🟡 Medium |
| Mobile sidebar | 🟡 Medium |
| Search / filter bar | 🟡 Medium |

---

## iOS app (FieldOpsAmbassador) — features

| Feature | Status | Notes |
|---|---|---|
| Real Supabase Auth (email/password) | ✅ | `AuthViewModel`; managers bounced to web |
| Session restore on launch | ✅ | `bootstrap()` |
| Role-aware tab shell (Schedule/Activity/Pay/Profile + Admin for managers) | ✅ | `MainTabView`; managers no longer bounced — they run solo demos here too |
| My Schedule (grouped: needs confirmation / pending / confirmed / past) | ✅ | `ScheduleView` → `EventDetailView` |
| Accept / Decline events | ✅ | RPC → `accept_event` / `decline_event` |
| GPS check-in / check-out | ✅ | `EventDetailView` + `LocationManager`; RPC `check_in_event`/`check_out_event` |
| Submit report (units/samples/feedback/photo count) | ✅ | `ReportFormView` → `submit_report`; real photo upload still TODO |
| Activity stats | ✅ | `ActivityView` — events, units, samples, avg lift |
| My Pay (payroll, auto-computed hours) | ✅ | `PayView`; hours from check-in/out |
| Profile editor (name/phone/address/shirt size) | ✅ | `ProfileView` + sign out |
| Manager Admin — add retailers, create/assign events | ✅ | `AdminView` → Stores/Events admin (direct writes via manager RLS) |
| Manager Admin — add ambassadors + email login invite | ✅ | `AmbassadorsAdminView` → `invite-ambassador` Edge Function (needs deploy) |
| Real report photo upload | 🔴 | Deferred — counts only for now |
| Push notifications | 🔴 | Not built |
| App icon | 🟡 | Placeholder "PS" mark — replace with real brand asset |
| TestFlight build | ⏳ | Project fully prepped; first archive/upload not yet done |

Models in app: `Profile`, `FieldEvent`, `Payment`.

---

## Backend (Supabase) — status

| Item | Status | Notes |
|---|---|---|
| Schema + sample data (`schema.sql`) | ✅ | 7 tables, RLS enabled |
| Role-based RLS + `get_my_role()` + `handle_new_user` trigger | ✅ | |
| `alter_v4.sql` — UUID linkage cols (`ambassador_id` on reports/payments), `accept_event`/`decline_event`, self-approval gaps closed on events + reports | ✅ | Run in production 2026-06-03 |
| `alter_v5.sql` — check-in/out columns + `check_in_event`/`check_out_event`/`submit_report` functions (auto-computes payroll hours) | ⏳ | **Run this in Supabase** to enable the new field-execution loop |
| `invite-ambassador` Edge Function (service-role; manager-gated email invites) | ⏳ | **Deploy** via `supabase functions deploy` to enable manager invites |
| Backfill old rows → `ambassador_id`, flip RLS to UUID-primary | ⏳ | Future migration; name-string matching still primary today |

---

## Suggested steps — to live & perfect

### 1. Ship the iOS beta (now)
- First **Archive → App Store Connect → TestFlight** upload from Xcode (project is prepped).
- Create the App Store Connect app record (name "FieldOps Ambassador", bundle `com.austinoblas.fieldopsambassador`).
- Add testers: internal (instant) and/or external group (one Beta App Review). Gather feedback.

### 2. Complete the ambassador loop in iOS (Phase 4)
The two disabled buttons are the gap between "view schedule" and "actually run a demo":
- **Check-in** — capture location/timestamp when arriving at a store.
- **Submit report** — units sold, samples, feedback, **photo upload** to Supabase Storage, writing `ambassador_id`.
- **My Payments** — read-only list mirroring the web view.

### 3. Real branding
- Replace the placeholder "PS" icon with the finished brand icon (1024 px, no alpha).
- Add a proper launch screen.

### 4. Security hardening (highest-value cleanup)
- **Web auth is the biggest hole.** The web client has no real login and a self-declared role, so server-side role enforcement can't fully protect manager actions there. Move the web app to Supabase Auth (email/password, same as iOS) so RLS protects the whole system consistently. This is the #1 item before wider rollout.
- Audit remaining RLS policies once both clients use real auth.

### 5. Backend migration to UUID-primary
- Backfill `ambassador_id` on historical `reports`/`payments`/`events`.
- Flip RLS to prefer `ambassador_id` over the legacy `ambassador` name string, then deprecate name matching.

### 6. Web polish (backlog)
- Photo uploads on reports, CSV export for payments, search/filter bar, mobile sidebar.

### 7. App Store release (beyond TestFlight)
- App screenshots, privacy policy URL, App Store listing copy, data-collection disclosures, submit for review.

---

## Build & run reference

```bash
# iOS — regenerate project after source/setting changes
cd FieldOps/FieldOpsAmbassador && xcodegen generate

# iOS — open to archive for TestFlight
open FieldOps/FieldOpsAmbassador/FieldOpsAmbassador.xcodeproj

# Web — edit index.html, commit, push; GitHub Pages redeploys in ~30s
```
