-- ════════════════════════════════════════════════════════════
--  FieldOps alter_v7.sql — invite hierarchy
--  Run in Supabase → SQL Editor → New Query. Idempotent / safe to re-run.
--
--  Makes signup carry role + region + manager from the invite metadata, so
--  invited managers/ambassadors land in the right region with the right role.
--  Roster rows and auth users are created by the Edge Functions (service role),
--  so no client-side insert hits RLS.
-- ════════════════════════════════════════════════════════════


-- ── handle_new_user: copy role / region_id / manager_id ────
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, email, name, role, region_id, manager_id)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', ''),
    coalesce(new.raw_user_meta_data->>'role', 'ambassador'),
    nullif(new.raw_user_meta_data->>'region_id', '')::bigint,
    nullif(new.raw_user_meta_data->>'manager_id', '')::uuid
  )
  on conflict (id) do nothing;
  return new;
end;
$$;


-- ════════════════════════════════════════════════════════════
--  BOOTSTRAP — make the HQ admin. Confirm this is your exact
--  login email (the one on your Supabase auth account).
-- ════════════════════════════════════════════════════════════
update profiles set role = 'admin' where email = 'aoblas@benefitbrands.com';
