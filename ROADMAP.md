# FieldOps — Roadmap

_Last updated: 2026-06-03. Companion to [PROJECT_STATUS.md](PROJECT_STATUS.md)._

The core national platform is built (org hierarchy, scheduling, geofenced execution, KPIs, payroll, invites). What follows is sequenced by value and readiness.

## Next up (high field value)

- [ ] **Report photos** — real image upload to Supabase Storage (storefront / display / crowd shots on reports). Needs: a Storage bucket + RLS, `photo_urls text[]` on reports, `PhotosPicker` + upload in the report form, thumbnails in manager review. _Currently reports store a photo count only._
- [ ] **Push notifications** — APNs via Supabase. Alert ambassadors when assigned a demo and the day-of; alert managers when a report lands or someone misses a check-in. Needs: APNs key, device-token table, a notify Edge Function / trigger.
- [ ] **Real brand app icon** — replace the placeholder "PS" mark with the finished ProSupps icon (1024px, no alpha).

## Operational (do as you onboard)

- [ ] **Onboard regions & managers** — HQ creates the 10 regions, invites each regional manager, managers invite their teams.
- [ ] **Legacy data hygiene** — backfill `region_id` on any pre-region events/reports/payments so they show up for the right manager (older rows are unassigned).
- [ ] **Geocode existing stores** — old seeded stores have no coordinates (no geofence). Re-add or batch-geocode them.
- [ ] **Supabase Pro plan (~$25/mo)** — free tier (50k rows / 500 MB / storage) won't hold ~300 demos/week + photos. Upgrade before scaling.
- [ ] **Email sending** — invites use Supabase's built-in SMTP (rate-limited). Add real SMTP (Authentication → Emails) for volume.

## Bigger features (own decisions)

- [ ] **Multi-ambassador per event** — staff several ambassadors on one demo. Invasive: join table + reworked check-in/report/payroll. Deferred by choice; revisit when big-event staffing is needed.
- [ ] **Web app strategy** — either retire it (iOS-for-everyone) or give it real Supabase Auth so HQ can use it as a large-screen dashboard. Currently self-declared-role + shared key (not trustworthy at scale).
- [ ] **Surveys** — wire the existing `surveys` table into the app (shopper feedback capture/rollup).

## Polish backlog (quick wins)

- [ ] Today highlight on manager dashboard (today's demos across the region)
- [ ] Tap-to-call / tap-to-email ambassadors (needs phone captured at invite)
- [ ] Manager team roster with per-ambassador performance
- [ ] Event detail: live distance-to-store indicator before check-in
- [ ] Pull more KPIs (no-shows, completion rate, $/unit)

## Always before a release

- [ ] Bump `CURRENT_PROJECT_VERSION` in `project.yml`, `xcodegen generate`, build clean (zero warnings), archive.
- [ ] Two-account **RLS isolation test** if any policy/region logic changed.
