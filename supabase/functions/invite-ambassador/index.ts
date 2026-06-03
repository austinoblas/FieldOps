// invite-ambassador — creates a login account for a new ambassador.
//
// The mobile app (anon key) cannot create auth users, so this runs server-side
// with the service-role key. It first verifies the *caller* is a manager, then
// sends a Supabase invite email. The handle_new_user trigger creates the
// matching profile (role 'ambassador') when they accept.
//
// Deploy:  supabase functions deploy invite-ambassador --project-ref jlzgpcrrwkcutpqjntku
// (SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY are injected automatically.)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json(401, { error: "Missing Authorization header" });

    const url = Deno.env.get("SUPABASE_URL")!;
    const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
    const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Verify the caller is an authenticated manager.
    const caller = createClient(url, anon, { global: { headers: { Authorization: authHeader } } });
    const { data: userData } = await caller.auth.getUser();
    const user = userData?.user;
    if (!user) return json(401, { error: "Not authenticated" });

    const { data: profile } = await caller
      .from("profiles").select("role").eq("id", user.id).single();
    if (profile?.role !== "manager") return json(403, { error: "Managers only" });

    const { email, name } = await req.json();
    if (!email) return json(400, { error: "email is required" });

    // Service-role invite.
    const admin = createClient(url, service);
    const { error } = await admin.auth.admin.inviteUserByEmail(email, {
      data: { name: name ?? "", role: "ambassador" },
    });
    if (error) return json(400, { error: error.message });

    return json(200, { ok: true });
  } catch (e) {
    return json(500, { error: String(e) });
  }
});
