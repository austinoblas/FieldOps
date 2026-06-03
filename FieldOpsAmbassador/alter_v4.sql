-- ════════════════════════════════════════════════════════════
--  FieldOps alter_v4.sql — Phase 1: native-app backend hardening
--  Run in Supabase → SQL Editor → New Query. Idempotent / safe to re-run.
--
--  Two goals:
--   1. Add UUID linkage columns for the iOS app (additive, non-breaking —
--      the web app keeps working off the existing `ambassador` name string).
--   2. Close the self-approval security gaps on events AND reports.
-- ════════════════════════════════════════════════════════════


-- ── 1. UUID LINKAGE (additive) ─────────────────────────────
-- The native app will write ambassador_id on every report/payment it creates,
-- while still populating the legacy `ambassador` name string so the web admin
-- view is unaffected. A later migration can backfill old rows and flip RLS to
-- be UUID-primary. Nothing breaks today.

alter table reports  add column if not exists ambassador_id uuid references profiles(id);
alter table payments add column if not exists ambassador_id uuid references profiles(id);

create index if not exists idx_reports_ambassador_id  on reports(ambassador_id);
create index if not exists idx_payments_ambassador_id on payments(ambassador_id);


-- ── 2a. EVENTS: close the self-approval gap ────────────────
-- The old "events_amb_update" policy had a USING clause but no WITH CHECK, so an
-- ambassador could UPDATE any column on their own event — including flipping a
-- 'pending_approval' request straight to 'upcoming' (self-approval). We drop the
-- broad direct-update path entirely and replace it with two SECURITY DEFINER
-- functions that permit ONLY the legitimate transitions.

drop policy if exists "events_amb_update" on events;

-- accept(): confirm attendance on an already-manager-approved event you own.
create or replace function accept_event(p_event_id bigint)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid  uuid := auth.uid();
  v_name text;
begin
  select name into v_name from profiles where id = v_uid;

  update events
     set accepted = true
   where id = p_event_id
     and status = 'upcoming'                               -- can't touch pending/completed
     and (ambassador_id = v_uid or ambassador = v_name);   -- must be yours

  if not found then
    raise exception 'Event not found, not yours, or not in an acceptable state';
  end if;
end;
$$;

-- decline(): withdraw from an event you own (upcoming or still pending approval).
create or replace function decline_event(p_event_id bigint)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid  uuid := auth.uid();
  v_name text;
begin
  select name into v_name from profiles where id = v_uid;

  update events
     set status = 'cancelled'
   where id = p_event_id
     and status in ('upcoming','pending_approval')
     and (ambassador_id = v_uid or ambassador = v_name);

  if not found then
    raise exception 'Event not found, not yours, or not declinable';
  end if;
end;
$$;

grant execute on function accept_event(bigint)  to authenticated;
grant execute on function decline_event(bigint) to authenticated;


-- ── 2b. REPORTS: same class of gap, same fix ───────────────
-- "rep_amb_update" also had USING but no WITH CHECK, so an ambassador editing
-- their own pending report could set status = 'approved' on the new row.
-- Re-create it with a WITH CHECK that pins the new status to 'pending' — they
-- can edit content, but only a manager can approve.

drop policy if exists "rep_amb_update" on reports;

create policy "rep_amb_update"
  on reports for update to authenticated
  using (
    get_my_role() = 'ambassador'
    and ambassador = (select name from profiles where id = auth.uid())
    and status = 'pending'
  )
  with check (
    get_my_role() = 'ambassador'
    and ambassador = (select name from profiles where id = auth.uid())
    and status = 'pending'
  );


-- ── DONE ───────────────────────────────────────────────────
-- Managers retain full access via their existing "*_manager" policies.
-- Ambassadors now have NO direct UPDATE path on events; accept/decline flow
-- only through accept_event()/decline_event().
