// invite-manager — the HQ admin invites a regional field manager.
//
// Admin-gated. Creates the auth user with role=manager + region_id (carried into
// the profile by the handle_new_user trigger) and links the region's lead.
//
// Deploy: supabase functions deploy invite-manager --project-ref jlzgpcrrwkcutpqjntku

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

    const { data: me } = await caller.from("profiles").select("role").eq("id", user.id).single();
    if (me?.role !== "admin") return json(403, { error: "Admins only" });

    const { email, name, region_id } = await req.json();
    if (!email || region_id == null) return json(400, { error: "email and region_id are required" });

    const admin = createClient(url, service);
    const { data: created, error: inviteErr } = await admin.auth.admin.inviteUserByEmail(email, {
      data: { name: name ?? "", role: "manager", region_id: String(region_id) },
    });
    if (inviteErr) return json(400, { error: inviteErr.message });

    // Link this region's lead.
    if (created?.user?.id) {
      await admin.from("regions").update({ manager_id: created.user.id }).eq("id", region_id);
    }

    return json(200, { ok: true });
  } catch (e) {
    return json(500, { error: String(e) });
  }
});
