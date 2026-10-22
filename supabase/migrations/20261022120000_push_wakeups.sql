-- Wake-up pushes (Firebase Cloud Messaging) for phones where MEYA is closed.
--
-- A sender marks an envelope with `notify` when it is something the
-- recipient sees: a message, a connection request, a call, or a reaction or
-- status (activity). Receipts and
-- other silent updates are never marked. For a marked envelope, the
-- functions/push function sends the recipient's phone an empty push: no
-- sender, no content. The phone then checks what is waiting.

alter table public.envelopes
  add column notify text check (notify in ('message', 'invite', 'call', 'activity'));

-- Each phone's Firebase push token.
create table public.push_tokens (
  device_id text primary key
    references public.devices (device_id) on delete cascade,
  token text not null check (char_length(token) between 1 and 4096),
  updated_at timestamptz not null default now()
);

alter table public.push_tokens enable row level security;

-- A phone may manage only its own token.
create policy "manage own push token"
  on public.push_tokens for all to authenticated
  using (device_id = public.my_device_id())
  with check (device_id = public.my_device_id());

-- When each phone was last woken, so a photo sent in many pieces does not
-- push many times (functions/push). No client access.
create table public.push_sent (
  device_id text primary key,
  last_at timestamptz not null default now()
);

alter table public.push_sent enable row level security;

create extension if not exists pg_net with schema extensions;

-- Calls functions/push for a marked envelope. Its address and the shared
-- secret come from Vault (tool/set-push-secrets.ps1); until they are set,
-- nothing is sent and envelopes are stored as before.
create or replace function public.wake_recipient()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  push_url text;
  push_secret text;
begin
  select decrypted_secret into push_url
    from vault.decrypted_secrets where name = 'meya_push_url';
  select decrypted_secret into push_secret
    from vault.decrypted_secrets where name = 'meya_push_secret';
  if push_url is null or push_secret is null then
    return new;
  end if;

  perform net.http_post(
    url := push_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-meya-push-secret', push_secret
    ),
    body := jsonb_build_object('device_id', new.recipient_device_id)
  );
  return new;
end
$$;

revoke all on function public.wake_recipient() from public, anon, authenticated;

create trigger envelopes_wake_recipient
  after insert on public.envelopes
  for each row
  when (new.notify is not null)
  execute function public.wake_recipient();
