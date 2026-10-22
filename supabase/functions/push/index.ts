// Sends an empty wake-up push (Firebase Cloud Messaging) to one phone.
//
// Called only by the database (trigger envelopes_wake_recipient), with a
// shared secret. The push carries no sender, no content and no type: the
// phone checks what is waiting for it. At most one push per phone every
// few seconds, so a photo sent in many pieces wakes it once.
//
// Secrets (tool/set-push-secrets.ps1):
//   MEYA_PUSH_SECRET           shared with the database trigger (Vault)
//   MEYA_FCM_SERVICE_ACCOUNT   the Firebase service account JSON
import { createClient } from "jsr:@supabase/supabase-js@2";

const DEVICE_ID = /^[A-Za-z0-9_-]{8,128}$/;
const MIN_INTERVAL_MS = 3_000;
const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

type ServiceAccount = { client_email: string; private_key: string; project_id: string };

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function sameText(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let difference = 0;
  for (let i = 0; i < a.length; i++) difference |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return difference === 0;
}

function base64Url(bytes: Uint8Array): string {
  let text = "";
  for (const byte of bytes) text += String.fromCharCode(byte);
  return btoa(text).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

let cachedToken: { value: string; expiresAt: number } | null = null;

/// A short-lived Google access token for sending pushes.
async function accessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt - 60 > now) return cachedToken.value;

  const encoder = new TextEncoder();
  const header = base64Url(encoder.encode(JSON.stringify({ alg: "RS256", typ: "JWT" })));
  const claims = base64Url(encoder.encode(JSON.stringify({
    iss: account.client_email,
    scope: FCM_SCOPE,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })));
  const pem = account.private_key
    .replace(/-----(BEGIN|END) PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  const key = await crypto.subtle.importKey(
    "pkcs8",
    Uint8Array.from(atob(pem), (c) => c.charCodeAt(0)),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, encoder.encode(`${header}.${claims}`)),
  );

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${header}.${claims}.${base64Url(signature)}`,
    }),
  });
  if (!response.ok) throw new Error(`Google sign-in failed (${response.status})`);
  const body = await response.json();
  cachedToken = { value: body.access_token, expiresAt: now + (body.expires_in ?? 3600) };
  return cachedToken.value;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const secret = Deno.env.get("MEYA_PUSH_SECRET") ?? "";
  const given = request.headers.get("x-meya-push-secret") ?? "";
  if (!secret || !sameText(given, secret)) return json({ error: "Forbidden" }, 403);

  let deviceId: unknown;
  try {
    deviceId = (await request.json()).device_id;
  } catch {
    return json({ error: "Invalid request" }, 400);
  }
  if (typeof deviceId !== "string" || !DEVICE_ID.test(deviceId)) {
    return json({ error: "Invalid request" }, 400);
  }

  const accountJson = Deno.env.get("MEYA_FCM_SERVICE_ACCOUNT");
  if (!accountJson) return json({ sent: false, reason: "not configured" });
  const account = JSON.parse(accountJson) as ServiceAccount;

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

  const { data: last } = await admin
    .from("push_sent").select("last_at").eq("device_id", deviceId).maybeSingle();
  if (last && Date.now() - new Date(last.last_at).getTime() < MIN_INTERVAL_MS) {
    return json({ sent: false, reason: "recently woken" });
  }

  const { data: row } = await admin
    .from("push_tokens").select("token").eq("device_id", deviceId).maybeSingle();
  if (!row) return json({ sent: false, reason: "no token" });

  await admin.from("push_sent").upsert({ device_id: deviceId, last_at: new Date().toISOString() });

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${await accessToken(account)}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: row.token,
          // Data only, high priority: wakes MEYA, which shows the
          // notification itself. The data says nothing about the message.
          data: { w: "1" },
          android: { priority: "HIGH", ttl: "3600s" },
        },
      }),
    },
  );

  if (response.status === 404 || response.status === 400) {
    // The phone uninstalled MEYA or the token changed: forget it.
    const body = await response.text();
    if (body.includes("UNREGISTERED") || body.includes("INVALID_ARGUMENT")) {
      await admin.from("push_tokens").delete().eq("device_id", deviceId);
    }
    return json({ sent: false, reason: "token rejected" });
  }
  if (!response.ok) return json({ sent: false, reason: `FCM ${response.status}` }, 502);
  return json({ sent: true });
});
