# FieldOps — Project Overview & Framework

_Last updated: 2026-06-03 · iOS app at version 1.3 (build 5 on TestFlight, repo set to build 6 for next archive)_

National field-marketing platform for ProSupps demos: a database of all field activity, scheduling at retailers, ambassador execution (check-in → report), KPI look-back, and payroll export. Built to scale to **10 regions × ~10-person teams, ~300 demos/week**.

---

## Links

| Resource | URL |
|---|---|
| **Live web app** | https://austinoblas.github.io/FieldOps/ |
| GitHub repo | https://github.com/austinoblas/FieldOps |
| Supabase project | `jlzgpcrrwkcutpqjntku` |
| iOS bundle ID | `com.austinoblas.fieldopsambassador` (team `5GAAU67LA2`) |

## Stack

- **iOS app** (primary client): `FieldOpsAmbassador/` — SwiftUI, iOS 17+, supabase-swift 2.x. XcodeGen-managed (`project.yml` is source of truth → run `xcodegen generate`). **Everyone uses the app** (ambassadors, regional managers, HQ admin).
- **Web app** (secondary): single-file `index.html` on GitHub Pages. Original admin tool; optional going forward (kept for HQ if wanted; would need real auth to be trusted at scale).
- **Backend**: Supabase Postgres + Row-Level Security + Edge Functions (Deno).

## Org model (national hierarchy)

| Role | Sees / manages |
|---|---|
| `admin` (HQ — aoblas@benefitbrands) | Everything, all regions. Invites managers, sees national dashboard/payroll. |
| `manager` (regional field manager) | Only their own region's ambassadors, events, reports, payroll. Also runs their own solo demos. Invites ambassadors. |
| `ambassador` | Only their own events. |

Region isolation is enforced by **Row-Level Security** (`is_admin()`, `get_my_region()`), with `region_id` denormalized onto events/reports/payments/ambassadors for fast, indexed checks.

---

## iOS feature inventory — all shipped ✅

**Everyone (ambassador loop):**
- Email/password auth; role-aware tab bar (Schedule · Activity · Pay · Profile, + Admin for managers/HQ)
- Schedule: **Today** section, color-coded statuses, accept/decline
- **GPS-geofenced check-in/out** (must be within 200 m of the store; server-enforced)
- Submit report (units, samples, feedback, photo count) → auto-completes event + generates payroll
- **Directions** to the store (Apple Maps)
- Activity stats; My Pay (auto-computed hours); editable Profile

**Managers / HQ (Admin tab):**
- **Dashboard**: period filter, KPI cards (demos, units, samples, avg lift, payroll), **Live now** (who's checked in), breakdowns by region/retailer/product
- **Payroll**: status filter, approve → mark paid, **CSV export** (region-scoped)
- **Events**: create & assign, **recurring demos**, shift times, **double-booking warnings**, search
- **Retailers**: add (auto-geocoded for geofencing), tap-to-call
- **Ambassadors**: invite by email, search
- **HQ only** — **Regions** management; **Field Managers**: invite a manager to a region

## Backend

**Tables:** profiles, regions, events, ambassadors, reports, payments, stores, surveys (all region-aware on the high-volume ones).

**Migrations (run in order in Supabase SQL Editor):**
| File | Purpose | Applied |
|---|---|---|
| `schema.sql` | base tables + RLS | ✅ |
| `alter_v4.sql` | UUID linkage, accept/decline, self-approval fixes | ✅ |
| `alter_v5.sql` | check-in/out + submit_report (payroll hours) | ✅ |
| `alter_v6.sql` | regions, 3-tier roles, region-scoped RLS, UUID backfill | ✅ |
| `alter_v7.sql` | invite metadata in handle_new_user; bootstrap admin | ✅ |
| `alter_v8.sql` | store coords + geofenced check-in/out (200 m) | ⬅️ **confirm applied** |

**Edge Functions (deployed, ACTIVE):**
- `invite-manager` — admin-gated; creates a manager auth user + region, links region lead.
- `invite-ambassador` — manager/admin-gated; creates ambassador auth user + roster row (service-role, region-stamped).

## Build & release

```bash
cd FieldOps/FieldOpsAmbassador && xcodegen generate   # after any source/setting change
open FieldOps/FieldOpsAmbassador/FieldOpsAmbassador.xcodeproj   # Archive → App Store Connect
```
- Version/build live in `project.yml` (`MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`) — let the repo drive it; **no need to hand-edit in Xcode**. Bump `CURRENT_PROJECT_VERSION` before each archive.
- Currently **1.3 (5)** on TestFlight; repo set to **build 6** for the next archive.

## ⚠️ Before relying on it at scale
Run the **two-account RLS isolation test**: a manager in Region A must NOT see Region B's events/payroll. RLS can only be verified against the live DB.
