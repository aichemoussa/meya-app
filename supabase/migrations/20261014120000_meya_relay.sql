-- MEYA relay on Supabase.
--
-- Supabase stores and forwards end-to-end encrypted envelopes; it never sees
-- message content, keys or contacts. Each phone signs in anonymously and
-- binds its MEYA device ID to that sign-in by proving it holds the device's
-- Ed25519 signing key (see functions/register-device).

-- One row per phone: its device ID, its Supabase (anonymous) user, and the
-- public signing key that proved ownership of the device ID.
create table public.devices (
  device_id text primary key
    check (device_id ~ '^[A-Za-z0-9_-]{8,128}$'),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  signing_public_key text not null check (char_length(signing_public_key) <= 64),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Encrypted envelopes waiting for their recipient. The recipient deletes each
-- one after handling it (the relay's "Ack").
create table public.envelopes (
  id text not null check (char_length(id) between 1 and 256),
  sender_device_id text not null references public.devices (device_id) on delete cascade,
  recipient_device_id text not null
    check (recipient_device_id ~ '^[A-Za-z0-9_-]{8,128}$'),
  -- base64 of at most 1 MiB, as with the relay.
  payload text not null check (octet_length(payload) <= 1400000),
  created_at timestamptz not null default now(),
  primary key (recipient_device_id, id)
);

create index envelopes_recipient_created on public.envelopes (recipient_device_id, created_at);

-- Rate limit for TURN credentials (functions/turn-credentials).
create table public.turn_requests (
  user_id uuid primary key references auth.users (id) on delete cascade,
  last_at timestamptz not null default now()
);

alter table public.devices enable row level security;
alter table public.envelopes enable row level security;
alter table public.turn_requests enable row level security;

-- The device ID of the signed-in phone, or null.
create or replace function public.my_device_id()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select device_id from public.devices where user_id = auth.uid()
$$;

revoke all on function public.my_device_id() from public, anon;
grant execute on function public.my_device_id() to authenticated;

-- A phone may read its own binding. Bindings are written only by
-- register-device after the signature is checked.
create policy "read own device"
  on public.devices for select to authenticated
  using (user_id = auth.uid());

-- A phone may send only as itself...
create policy "send as own device"
  on public.envelopes for insert to authenticated
  with check (sender_device_id = public.my_device_id());

-- ...and read and remove only envelopes addressed to it.
create policy "read own envelopes"
  on public.envelopes for select to authenticated
  using (recipient_device_id = public.my_device_id());

create policy "remove own envelopes"
  on public.envelopes for delete to authenticated
  using (recipient_device_id = public.my_device_id());

-- turn_requests: no client access at all (service role only).

-- Live delivery: phones are told when a new envelope arrives for them.
alter publication supabase_realtime add table public.envelopes;
