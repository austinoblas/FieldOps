// invite-ambassador — a manager (or admin) invites an ambassador to a region.
//
// Runs with the service-role key, so it both bypasses the ambassadors-table RLS
// and stamps the new user's region/manager. A manager can only invite into their
// own region; an admin may pass a region_id.
//
// Deploy: supabase functions deploy invite-ambassador --project-ref jlzgpcrrwkcutpqjntku

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json(401, { error: "Missing Authorization header" });

    const url = Deno.env.get("SUPABASE_URL")!;
    const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
    const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const caller = createClient(url, anon, { global: { headers: { Authorization: authHeader } } });
    const { data: udata } = await caller.auth.getUser();
    const user = udata?.user;
    if (!user) return json(401, { error: "Not authenticated" });

    const { data: me } = await caller.from("profiles").select("role, region_id").eq("id", user.id).single();
    if (me?.role !== "manager" && me?.role !== "admin") return json(403, { error: "Managers or admins only" });

    const { email, name, rate, region_id } = await req.json();
    if (!email) return json(400, { error: "email is required" });

    // Managers are pinned to their own region; admins may target a region.
    const region = me.role === "manager" ? me.region_id : (region_id ?? null);
    const manager = me.role === "manager" ? user.id : null;

    const admin = createClient(url, service);
    const { error: inviteErr } = await admin.auth.admin.inviteUserByEmail(email, {
      data: {
        name: name ?? "",
        role: "ambassador",
        region_id: region != null ? String(region) : "",
        manager_id: manager ?? "",
      },
    });
    if (inviteErr) return json(400, { error: inviteErr.message });

    // Roster row (rate drives payroll). Service role => no RLS issue.
    await admin.from("ambassadors").insert({
      name: name ?? "", email, rate: rate ?? 0, status: "active", region_id: region,
    });

    return json(200, { ok: true });
  } catch (e) {
    return json(500, { error: String(e) });
  }
});
