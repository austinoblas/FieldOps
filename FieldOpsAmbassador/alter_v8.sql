-- ════════════════════════════════════════════════════════════
--  FieldOps alter_v8.sql — geofenced check-in / check-out
--  Run in Supabase → SQL Editor → New Query. Idempotent / safe to re-run.
--
--  Check-in and check-out now must happen physically at the store. Stores carry
--  lat/lng (geocoded by the app), events copy the store coords, and the RPCs
--  reject a check-in/out beyond a radius. Events with no store coords are not
--  geofenced (graceful for legacy / un-geocoded stores).
-- ════════════════════════════════════════════════════════════


-- ── 1. COORDINATES ─────────────────────────────────────────
alter table stores add column if not exists lat numeric;
alter table stores add column if not exists lng numeric;
alter table events add column if not exists store_lat numeric;
alter table events add column if not exists store_lng numeric;


-- ── 2. DISTANCE HELPER (haversine, metres) ─────────────────
create or replace function meters_between(lat1 numeric, lng1 numeric, lat2 numeric, lng2 numeric)
returns numeric language sql immutable as $$
  select 2 * 6371000 * asin(sqrt(
    power(sin(radians(lat2 - lat1) / 2), 2) +
    cos(radians(lat1)) * cos(radians(lat2)) * power(sin(radians(lng2 - lng1) / 2), 2)
  ));
$$;


-- ── 3. GEOFENCED CHECK IN ──────────────────────────────────
create or replace function check_in_event(p_event_id bigint, p_lat numeric, p_lng numeric)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid(); v_name text; v_event events%rowtype; v_dist numeric;
begin
  select name into v_name from profiles where id = v_uid;
  select * into v_event from events
   where id = p_event_id and status = 'upcoming'
     and (ambassador_id = v_uid or ambassador = v_name);
  if not found then raise exception 'Event not found, not yours, or not in a checkable state'; end if;

  if v_event.store_lat is not null and v_event.store_lng is not null then
    if p_lat is null or p_lng is null then
      raise exception 'Location required — enable location to check in at the store';
    end if;
    v_dist := meters_between(p_lat, p_lng, v_event.store_lat, v_event.store_lng);
    if v_dist > 200 then
      raise exception 'You must be at the store to check in (you are % m away)', round(v_dist);
    end if;
  end if;

  update events set check_in_at = now(), check_in_lat = p_lat, check_in_lng = p_lng where id = p_event_id;
end;
$$;


-- ── 4. GEOFENCED CHECK OUT ─────────────────────────────────
create or replace function check_out_event(p_event_id bigint, p_lat numeric, p_lng numeric)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid(); v_name text; v_event events%rowtype; v_dist numeric;
begin
  select name into v_name from profiles where id = v_uid;
  select * into v_event from events
   where id = p_event_id and check_in_at is not null
     and (ambassador_id = v_uid or ambassador = v_name);
  if not found then raise exception 'Event not found, not yours, or not checked in'; end if;

  if v_event.store_lat is not null and v_event.store_lng is not null then
    if p_lat is null or p_lng is null then
      raise exception 'Location required — enable location to check out at the store';
    end if;
    v_dist := meters_between(p_lat, p_lng, v_event.store_lat, v_event.store_lng);
    if v_dist > 200 then
      raise exception 'You must be at the store to check out (you are % m away)', round(v_dist);
    end if;
  end if;

  update events set check_out_at = now(), check_out_lat = p_lat, check_out_lng = p_lng where id = p_event_id;
end;
$$;
