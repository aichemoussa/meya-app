// Short-lived Cloudflare Realtime TURN credentials for a call.
//
// Set the secrets once (never in the app):
//   supabase secrets set MEYA_TURN_KEY_ID=... MEYA_TURN_KEY_TOKEN=...
// Without them, or if Cloudflare is unreachable, this returns STUN only and
// calls still connect whenever the two phones can reach each other directly.
import { createClient } from "jsr:@supabase/supabase-js@2";

const STUN_ONLY = [{ urls: ["stun:stun.cloudflare.com:3478"] }];
const MIN_INTERVAL_MS = 10_000;
const TTL_SECONDS = 4 * 60 * 60;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
  const token = (request.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  const { data: auth, error } = await admin.auth.getUser(token);
  if (error || !auth.user) return json({ error: "Not signed in" }, 401);

  const keyId = Deno.env.get("MEYA_TURN_KEY_ID");
  const apiToken = Deno.env.get("MEYA_TURN_KEY_TOKEN");
  if (!keyId || !apiToken) return json({ ice_servers: STUN_ONLY });

  // At most one request every 10 seconds per phone, so one device cannot
  // run up the TURN bill.
  const { data: last } = await admin
    .from("turn_requests")
    .select("last_at")
    .eq("user_id", auth.user.id)
    .maybeSingle();
  if (last && Date.now() - new Date(last.last_at).getTime() < MIN_INTERVAL_MS) {
    return json({ ice_servers: STUN_ONLY });
  }
  await admin.from("turn_requests").upsert({
    user_id: auth.user.id,
    last_at: new Date().toISOString(),
  });

  try {
    const response = await fetch(
      `https://rtc.live.cloudflare.com/v1/turn/keys/${keyId}/credentials/generate-ice-servers`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ ttl: TTL_SECONDS }),
      },
    );
    if (!response.ok) return json({ ice_servers: STUN_ONLY });
    const body = await response.json();
    return json({ ice_servers: body.iceServers ?? STUN_ONLY });
  } catch {
    return json({ ice_servers: STUN_ONLY });
  }
});
