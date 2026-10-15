// Binds a MEYA device ID to the caller's anonymous Supabase sign-in.
//
// The phone proves it holds the device's Ed25519 signing key (the same key
// the self-hosted relay uses) by signing
//   "MEYA supabase binding v1\n<device_id>\n<supabase user id>"
// A device ID stays bound to its first key forever; a phone that lost its
// Supabase session (e.g. reinstall with the same keys) can bind again by
// signing with that key.
import { createClient } from "jsr:@supabase/supabase-js@2";

const DEVICE_ID = /^[A-Za-z0-9_-]{8,128}$/;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function fromBase64(value: string): Uint8Array {
  return Uint8Array.from(atob(value), (c) => c.charCodeAt(0));
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

  const token = (request.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  const { data: auth, error: authError } = await admin.auth.getUser(token);
  if (authError || !auth.user) return json({ error: "Not signed in" }, 401);
  const userId = auth.user.id;

  let body: { device_id?: unknown; public_key?: unknown; signature?: unknown };
  try {
    body = await request.json();
  } catch {
    return json({ error: "Invalid request" }, 400);
  }
  const { device_id: deviceId, public_key: publicKey, signature } = body;
  if (
    typeof deviceId !== "string" || !DEVICE_ID.test(deviceId) ||
    typeof publicKey !== "string" || publicKey.length > 64 ||
    typeof signature !== "string" || signature.length > 128
  ) {
    return json({ error: "Invalid request" }, 400);
  }

  let verified = false;
  try {
    const keyBytes = fromBase64(publicKey);
    const signatureBytes = fromBase64(signature);
    if (keyBytes.length !== 32 || signatureBytes.length !== 64) {
      return json({ error: "Invalid key or signature" }, 400);
    }
    const key = await crypto.subtle.importKey(
      "raw",
      keyBytes,
      { name: "Ed25519" },
      false,
      ["verify"],
    );
    const message = new TextEncoder().encode(
      `MEYA supabase binding v1\n${deviceId}\n${userId}`,
    );
    verified = await crypto.subtle.verify({ name: "Ed25519" }, key, signatureBytes, message);
  } catch {
    verified = false;
  }
  if (!verified) return json({ error: "Signature verification failed" }, 403);

  const { data: existing, error: readError } = await admin
    .from("devices")
    .select("signing_public_key, user_id")
    .eq("device_id", deviceId)
    .maybeSingle();
  if (readError) return json({ error: "Could not read device binding" }, 500);

  if (existing && existing.signing_public_key !== publicKey) {
    return json({ error: "Device ID is bound to a different key" }, 409);
  }

  // One device per sign-in: drop any other binding this user had.
  await admin.from("devices").delete().eq("user_id", userId).neq("device_id", deviceId);

  const now = new Date().toISOString();
  const { error: writeError } = existing
    ? await admin.from("devices").update({ user_id: userId, updated_at: now }).eq("device_id", deviceId)
    : await admin.from("devices").insert({
      device_id: deviceId,
      user_id: userId,
      signing_public_key: publicKey,
    });
  if (writeError) return json({ error: "Could not store device binding" }, 500);

  return json({ device_id: deviceId });
});
