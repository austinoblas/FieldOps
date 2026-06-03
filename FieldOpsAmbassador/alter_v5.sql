-- ════════════════════════════════════════════════════════════
--  FieldOps alter_v5.sql — Phase 2: field-execution loop
--  Run in Supabase → SQL Editor → New Query. Idempotent / safe to re-run.
--
--  Adds GPS check-in/out to events and three SECURITY DEFINER functions
--  (check_in_event / check_out_event / submit_report) so BOTH ambassadors
--  and managers-doing-solo-demos drive the same flow. Ownership is validated
--  inside each function, so they work regardless of role.
-- ════════════════════════════════════════════════════════════


-- ── 1. CHECK-IN / CHECK-OUT COLUMNS ────────────────────────
alter table events add column if not exists check_in_at  timestamptz;
alter table events add column if not exists check_out_at  timestamptz;
alter table events add column if not exists check_in_lat  numeric;
alter table events add column if not exists check_in_lng  numeric;
alter table events add column if not exists check_out_lat numeric;
alter table events add column if not exists check_out_lng numeric;


-- ── 2. CHECK IN ────────────────────────────────────────────
create or replace function check_in_event(p_event_id bigint, p_lat numeric, p_lng numeric)
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
     set check_in_at = now(), check_in_lat = p_lat, check_in_lng = p_lng
   where id = p_event_id
     and status = 'upcoming'
     and (ambassador_id = v_uid or ambassador = v_name);

  if not found then
    raise exception 'Event not found, not yours, or not in a checkable state';
  end if;
end;
$$;


-- ── 3. CHECK OUT ───────────────────────────────────────────
create or replace function check_out_event(p_event_id bigint, p_lat numeric, p_lng numeric)
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
     set check_out_at = now(), check_out_lat = p_lat, check_out_lng = p_lng
   where id = p_event_id
     and check_in_at is not null
     and (ambassador_id = v_uid or ambassador = v_name);

  if not found then
    raise exception 'Event not found, not yours, or not checked in';
  end if;
end;
$$;


-- ── 4. SUBMIT REPORT ───────────────────────────────────────
-- Writes the report, marks the event completed, and creates/refreshes a
-- pending payment with hours auto-computed from check-in/out and the rate
-- pulled from the ambassador roster (0 if not on the roster, e.g. a manager).
create or replace function submit_report(
  p_event_id bigint,
  p_units    integer,
  p_samples  integer,
  p_feedback text,
  p_photos   integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid   uuid := auth.uid();
  v_name  text;
  v_event events%rowtype;
  v_hours numeric := 0;
  v_rate  numeric := 0;
begin
  select name into v_name from profiles where id = v_uid;

  select * into v_event from events
   where id = p_event_id
     and (ambassador_id = v_uid or ambassador = v_name);
  if not found then
    raise exception 'Event not found or not yours';
  end if;

  if v_event.check_in_at is not null and v_event.check_out_at is not null then
    v_hours := round(extract(epoch from (v_event.check_out_at - v_event.check_in_at)) / 3600.0, 2);
  end if;

  select coalesce(rate, 0) into v_rate from ambassadors where name = v_name limit 1;
  v_rate := coalesce(v_rate, 0);

  insert into reports (event_name, ambassador, ambassador_id, date, status, units_sold, samples, feedback, photos, sales_lift)
  values (v_event.name, v_name, v_uid, coalesce(v_event.date, current_date), 'pending',
          coalesce(p_units, 0), coalesce(p_samples, 0), p_feedback, coalesce(p_photos, 0), 0);

  update events
     set status = 'completed', units_sold = p_units, samples = p_samples
   where id = p_event_id;

  if exists (select 1 from payments where event_name = v_event.name and ambassador = v_name) then
    update payments
       set hours = v_hours, rate = v_rate, total = round(v_hours * v_rate, 2)
     where event_name = v_event.name and ambassador = v_name;
  else
    insert into payments (ambassador, ambassador_id, event_name, date, hours, rate, expenses, total, status)
    values (v_name, v_uid, v_event.name, coalesce(v_event.date, current_date),
            v_hours, v_rate, 0, round(v_hours * v_rate, 2), 'pending');
  end if;
end;
$$;


grant execute on function check_in_event(bigint, numeric, numeric)  to authenticated;
grant execute on function check_out_event(bigint, numeric, numeric) to authenticated;
grant execute on function submit_report(bigint, integer, integer, text, integer) to authenticated;
