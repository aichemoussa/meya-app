use axum::{
    extract::{
        ws::{Message, WebSocket},
        Query, State, WebSocketUpgrade,
    },
    http::StatusCode,
    response::IntoResponse,
    routing::get,
    Router,
};
use base64::{engine::general_purpose::STANDARD as BASE64, Engine as _};
use ed25519_dalek::{Signature, Verifier, VerifyingKey};
use futures_util::{SinkExt, StreamExt};
use rusqlite::{params, Connection, OptionalExtension};
use serde::{Deserialize, Serialize};
use std::{collections::HashMap, net::SocketAddr, sync::Arc, time::Duration};
use tokio::{sync::{mpsc, Mutex}, time::timeout};
use tracing::{error, info};
use uuid::Uuid;

type SharedState = Arc<RelayState>;
const AUTH_TIMEOUT_SECONDS: u64 = 10;
const MAX_ENVELOPE_BYTES: usize = 1_048_576;
const SIGNING_KEY_LENGTH: usize = 32;
/// Cloudflare closes idle WebSockets after about 100 seconds.
const PING_INTERVAL_SECONDS: u64 = 25;
const TURN_MIN_INTERVAL_SECONDS: u64 = 10;
/// TURN credentials last for the longest call we expect.
const TURN_TTL_SECONDS: u64 = 4 * 60 * 60;

/// Cloudflare Realtime TURN key, from MEYA_TURN_KEY_ID and
/// MEYA_TURN_KEY_TOKEN. The token never leaves the relay.
#[derive(Clone)]
struct TurnConfig {
    key_id: String,
    api_token: String,
}

#[derive(Clone)]
struct RelayState {
    connections: Arc<Mutex<HashMap<String, mpsc::UnboundedSender<Message>>>>,
    database: Arc<Mutex<Connection>>,
    turn: Option<TurnConfig>,
    http: reqwest::Client,
    /// Last TURN request per device, to stop one device running up costs.
    turn_requests: Arc<Mutex<HashMap<String, std::time::Instant>>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Envelope {
    id: String,
    sender_device_id: String,
    recipient_device_id: String,
    payload: String,
}

#[derive(Debug, Deserialize)]
struct WsQuery {
    device_id: String,
}

#[derive(Debug, Serialize)]
struct HealthResponse {
    status: &'static str,
    service: &'static str,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "type")]
enum ClientMessage {
    Send { envelope: Envelope },
    Ack { envelope_id: String },
    /// Asks for short-lived TURN credentials before a call.
    TurnRequest,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "type")]
enum AuthenticationMessage {
    Register { public_key: String, signature: String },
    Authenticate { signature: String },
}

#[derive(Debug, Serialize)]
#[serde(tag = "type")]
enum ServerMessage {
    Challenge {
        device_id: String,
        nonce: String,
        registration_required: bool,
    },
    Authenticated { device_id: String },
    Envelope { envelope: Envelope },
    Error { error: String },
    /// ICE servers for WebRTC calls (STUN, plus TURN when configured).
    TurnServers { ice_servers: serde_json::Value },
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter("info")
        .init();

    let database_path =
        std::env::var("MEYA_RELAY_DB").unwrap_or_else(|_| "meya_relay.db".to_string());
    let database = Connection::open(&database_path)
        .expect("Failed to open relay database");
    initialize_database(&database)
        .expect("Failed to initialize relay database");

    let turn = match (
        std::env::var("MEYA_TURN_KEY_ID"),
        std::env::var("MEYA_TURN_KEY_TOKEN"),
    ) {
        (Ok(key_id), Ok(api_token)) if !key_id.is_empty() && !api_token.is_empty() => {
            info!("TURN credentials enabled (Cloudflare Realtime TURN)");
            Some(TurnConfig { key_id, api_token })
        }
        _ => {
            info!("TURN not configured; calls get STUN only");
            None
        }
    };

    let state = Arc::new(RelayState {
        connections: Arc::new(Mutex::new(HashMap::new())),
        database: Arc::new(Mutex::new(database)),
        turn,
        http: reqwest::Client::builder()
            .timeout(Duration::from_secs(10))
            .build()
            .expect("Failed to build HTTP client"),
        turn_requests: Arc::new(Mutex::new(HashMap::new())),
    });

    let app = Router::new()
        .route("/health", get(health))
        .route("/v1/ws", get(websocket))
        .with_state(state);

    // Behind a tunnel, set MEYA_RELAY_ADDR=127.0.0.1:8787 so only the tunnel
    // (and adb) can reach the relay.
    let address: SocketAddr = std::env::var("MEYA_RELAY_ADDR")
        .ok()
        .and_then(|value| value.parse().ok())
        .unwrap_or_else(|| SocketAddr::from(([0, 0, 0, 0], 8787)));
    info!("MEYA relay listening on {address}");

    let listener = tokio::net::TcpListener::bind(address)
        .await
        .expect("Failed to bind relay listener");
    axum::serve(listener, app)
        .await
        .expect("Relay server failed");
}

async fn health() -> impl IntoResponse {
    (
        StatusCode::OK,
        axum::Json(HealthResponse {
            status: "ok",
            service: "meya-relay",
        }),
    )
}

async fn websocket(
    ws: WebSocketUpgrade,
    Query(query): Query<WsQuery>,
    State(state): State<SharedState>,
) -> impl IntoResponse {
    let device_id = query.device_id.trim().to_string();
    if device_id.is_empty() || device_id.len() > 128 {
        return ws.on_upgrade(|mut socket| async move {
            send_server_message(
                &mut socket,
                &ServerMessage::Error {
                    error: "A valid device_id is required".to_string(),
                },
            )
            .await;
        });
    }

    ws.on_upgrade(move |socket| handle_socket(socket, device_id, state))
}

async fn handle_socket(socket: WebSocket, device_id: String, state: SharedState) {
    let (mut sender, mut receiver) = socket.split();
    let registered_key = match load_device_key(&state, &device_id).await {
        Ok(key) => key,
        Err(error) => {
            error!("Could not load device binding: {error}");
            let _ = sender
                .send(Message::Text(
                    serde_json::to_string(&ServerMessage::Error {
                        error: "Relay authentication could not be initialized".to_string(),
                    })
                    .unwrap_or_default()
                    .into(),
                ))
                .await;
            return;
        }
    };

    let nonce = Uuid::new_v4().to_string();
    let challenge = ServerMessage::Challenge {
        device_id: device_id.clone(),
        nonce: nonce.clone(),
        registration_required: registered_key.is_none(),
    };
    if send_split_message(&mut sender, &challenge).await.is_err() {
        return;
    }

    let auth_frame = match timeout(
        Duration::from_secs(AUTH_TIMEOUT_SECONDS),
        receiver.next(),
    )
    .await
    {
        Ok(Some(Ok(Message::Text(text)))) => text.to_string(),
        _ => {
            send_split_message(
                &mut sender,
                &ServerMessage::Error {
                    error: "Relay authentication timed out".to_string(),
                },
            )
            .await
            .ok();
            return;
        }
    };

    if let Err(reason) = authenticate_device(
        &state,
        &device_id,
        &nonce,
        registered_key.as_deref(),
        &auth_frame,
    )
    .await
    {
        error!("Relay authentication rejected for device {device_id}: {reason}");
        send_split_message(
            &mut sender,
            &ServerMessage::Error {
                error: "Relay authentication failed".to_string(),
            },
        )
        .await
        .ok();
        return;
    }

    let (outgoing_tx, mut outgoing_rx) = mpsc::unbounded_channel::<Message>();
    {
        let mut connections = state.connections.lock().await;
        connections.insert(device_id.clone(), outgoing_tx.clone());
    }

    if send_split_message(
        &mut sender,
        &ServerMessage::Authenticated {
            device_id: device_id.clone(),
        },
    )
    .await
    .is_err()
    {
        remove_connection(&state, &device_id, &outgoing_tx).await;
        return;
    }

    info!("Authenticated device connected: {device_id}");

    let pending = load_pending_envelopes(&state, &device_id).await;
    for envelope in pending {
        if send_split_message(&mut sender, &ServerMessage::Envelope { envelope })
            .await
            .is_err()
        {
            remove_connection(&state, &device_id, &outgoing_tx).await;
            return;
        }
    }

    let send_task = tokio::spawn(async move {
        let mut ping = tokio::time::interval(Duration::from_secs(PING_INTERVAL_SECONDS));
        ping.tick().await;
        loop {
            let message = tokio::select! {
                message = outgoing_rx.recv() => match message {
                    Some(message) => message,
                    None => break,
                },
                _ = ping.tick() => Message::Ping(Vec::new().into()),
            };
            if sender.send(message).await.is_err() {
                break;
            }
        }
    });

    while let Some(result) = receiver.next().await {
        match result {
            Ok(Message::Text(text)) => {
                if let Err(reason) = process_client_message(&device_id, &text, &state, &outgoing_tx).await {
                    error!("Message processing failed for authenticated device {device_id}: {reason}");
                    let message = ServerMessage::Error { error: reason };
                    if let Ok(serialized) = serde_json::to_string(&message) {
                        let _ = outgoing_tx.send(Message::Text(serialized.into()));
                    }
                }
            }
            Ok(Message::Binary(bytes)) => {
                if let Ok(text) = String::from_utf8(bytes.to_vec()) {
                    if let Err(reason) = process_client_message(&device_id, &text, &state, &outgoing_tx).await {
                        error!("Binary message processing failed for authenticated device {device_id}: {reason}");
                    }
                } else {
                    error!("Ignoring invalid binary client message");
                }
            }
            Ok(Message::Ping(payload)) => {
                let _ = outgoing_tx.send(Message::Pong(payload));
            }
            Ok(Message::Pong(_)) => {}
            Ok(Message::Close(_)) => break,
            Err(reason) => {
                error!("WebSocket error for {device_id}: {reason}");
                break;
            }
        }
    }

    send_task.abort();
    remove_connection(&state, &device_id, &outgoing_tx).await;
    info!("Authenticated device disconnected: {device_id}");
}

async fn authenticate_device(
    state: &SharedState,
    device_id: &str,
    nonce: &str,
    registered_key: Option<&[u8]>,
    auth_frame: &str,
) -> Result<(), String> {
    let message: AuthenticationMessage = serde_json::from_str(auth_frame)
        .map_err(|_| "Invalid authentication message".to_string())?;
    let payload = format!("MEYA relay authentication v1\n{device_id}\n{nonce}");

    match (registered_key, message) {
        (None, AuthenticationMessage::Register { public_key, signature }) => {
            let key_bytes = BASE64
                .decode(public_key)
                .map_err(|_| "Invalid registration public key".to_string())?;
            verify_signature(&key_bytes, &payload, &signature)?;

            {
                let database = state.database.lock().await;
                database
                    .execute(
                        "INSERT OR IGNORE INTO device_bindings (device_id, signing_public_key) VALUES (?1, ?2)",
                        params![device_id, key_bytes],
                    )
                    .map_err(|_| "Could not store device binding".to_string())?;
                let stored: Vec<u8> = database
                    .query_row(
                        "SELECT signing_public_key FROM device_bindings WHERE device_id = ?1",
                        params![device_id],
                        |row| row.get(0),
                    )
                    .map_err(|_| "Could not verify stored device binding".to_string())?;
                if stored != key_bytes {
                    return Err("Device ID is already bound to a different signing key".to_string());
                }
            }
            Ok(())
        }
        (Some(key_bytes), AuthenticationMessage::Authenticate { signature }) => {
            verify_signature(key_bytes, &payload, &signature)
        }
        (None, _) => Err("First connection must register a signing key".to_string()),
        (Some(_), _) => Err("Registered device must authenticate with its existing key".to_string()),
    }
}

fn verify_signature(public_key: &[u8], payload: &str, encoded_signature: &str) -> Result<(), String> {
    if public_key.len() != SIGNING_KEY_LENGTH {
        return Err("Invalid signing public key length".to_string());
    }
    let key_array: [u8; SIGNING_KEY_LENGTH] = public_key
        .try_into()
        .map_err(|_| "Invalid signing public key".to_string())?;
    let key = VerifyingKey::from_bytes(&key_array)
        .map_err(|_| "Invalid signing public key".to_string())?;
    let signature_bytes = BASE64
        .decode(encoded_signature)
        .map_err(|_| "Invalid authentication signature encoding".to_string())?;
    let signature = Signature::from_slice(&signature_bytes)
        .map_err(|_| "Invalid authentication signature length".to_string())?;
    key.verify(payload.as_bytes(), &signature)
        .map_err(|_| "Authentication signature verification failed".to_string())
}

async fn load_device_key(state: &SharedState, device_id: &str) -> Result<Option<Vec<u8>>, String> {
    let database = state.database.lock().await;
    database
        .query_row(
            "SELECT signing_public_key FROM device_bindings WHERE device_id = ?1",
            params![device_id],
            |row| row.get(0),
        )
        .optional()
        .map_err(|_| "Failed to read device binding".to_string())
}

async fn send_split_message(
    sender: &mut futures_util::stream::SplitSink<WebSocket, Message>,
    message: &ServerMessage,
) -> Result<(), String> {
    let serialized = serde_json::to_string(message).map_err(|_| "Failed to serialize relay message".to_string())?;
    sender
        .send(Message::Text(serialized.into()))
        .await
        .map_err(|_| "Failed to send relay message".to_string())
}

async fn send_server_message(socket: &mut WebSocket, message: &ServerMessage) {
    if let Ok(serialized) = serde_json::to_string(message) {
        let _ = socket.send(Message::Text(serialized.into())).await;
    }
}

async fn remove_connection(
    state: &SharedState,
    device_id: &str,
    outgoing_tx: &mpsc::UnboundedSender<Message>,
) {
    let mut connections = state.connections.lock().await;
    if connections
        .get(device_id)
        .is_some_and(|current| current.same_channel(outgoing_tx))
    {
        connections.remove(device_id);
    }
}

async fn process_client_message(
    connected_device_id: &str,
    text: &str,
    state: &SharedState,
    outgoing_tx: &mpsc::UnboundedSender<Message>,
) -> Result<(), String> {
    let message: ClientMessage = serde_json::from_str(text).map_err(|_| "Invalid client message".to_string())?;
    match message {
        ClientMessage::Send { envelope } => {
            if envelope.sender_device_id != connected_device_id {
                return Err("Envelope sender does not match authenticated device".to_string());
            }
            if envelope.id.trim().is_empty() || envelope.id.len() > 256 {
                return Err("Envelope ID is invalid".to_string());
            }
            if envelope.recipient_device_id.trim().is_empty() || envelope.recipient_device_id.len() > 128 {
                return Err("Envelope recipient is invalid".to_string());
            }
            let payload = BASE64.decode(&envelope.payload)
                .map_err(|_| "Envelope payload is not valid base64".to_string())?;
            if payload.is_empty() || payload.len() > MAX_ENVELOPE_BYTES {
                return Err("Envelope payload size is invalid".to_string());
            }
            store_envelope(state, &envelope, &payload).await?;
            deliver_envelope(state, &envelope).await
        }
        ClientMessage::Ack { envelope_id } => {
            if envelope_id.trim().is_empty() || envelope_id.len() > 256 {
                return Err("Acknowledgement ID is invalid".to_string());
            }
            acknowledge_envelope(state, connected_device_id, &envelope_id).await
        }
        ClientMessage::TurnRequest => {
            let ice_servers = turn_servers(state, connected_device_id).await?;
            let serialized = serde_json::to_string(&ServerMessage::TurnServers { ice_servers })
                .map_err(|_| "Failed to serialize ICE servers".to_string())?;
            outgoing_tx
                .send(Message::Text(serialized.into()))
                .map_err(|_| "Device connection is unavailable".to_string())
        }
    }
}

/// STUN only, used when TURN is not configured or Cloudflare cannot be reached.
fn stun_only() -> serde_json::Value {
    serde_json::json!([{ "urls": ["stun:stun.cloudflare.com:3478"] }])
}

/// Fresh, short-lived TURN credentials from Cloudflare Realtime TURN.
/// Rate-limited per device; falls back to STUN only on any failure, so a
/// call can still connect directly.
async fn turn_servers(state: &SharedState, device_id: &str) -> Result<serde_json::Value, String> {
    let Some(turn) = state.turn.clone() else {
        return Ok(stun_only());
    };
    {
        let mut requests = state.turn_requests.lock().await;
        let now = std::time::Instant::now();
        if let Some(last) = requests.get(device_id) {
            if now.duration_since(*last) < Duration::from_secs(TURN_MIN_INTERVAL_SECONDS) {
                return Ok(stun_only());
            }
        }
        requests.insert(device_id.to_string(), now);
        if requests.len() > 10_000 {
            requests.retain(|_, time| now.duration_since(*time) < Duration::from_secs(3600));
        }
    }
    let url = format!(
        "https://rtc.live.cloudflare.com/v1/turn/keys/{}/credentials/generate-ice-servers",
        turn.key_id
    );
    let response = state
        .http
        .post(url)
        .bearer_auth(&turn.api_token)
        .json(&serde_json::json!({ "ttl": TURN_TTL_SECONDS }))
        .send()
        .await;
    match response {
        Ok(response) if response.status().is_success() => {
            let body: serde_json::Value = response
                .json()
                .await
                .map_err(|_| "Invalid TURN response".to_string())?;
            Ok(body.get("iceServers").cloned().unwrap_or_else(stun_only))
        }
        Ok(response) => {
            error!("TURN credential request failed: HTTP {}", response.status());
            Ok(stun_only())
        }
        Err(reason) => {
            error!("TURN credential request failed: {reason}");
            Ok(stun_only())
        }
    }
}

async fn store_envelope(state: &SharedState, envelope: &Envelope, payload: &[u8]) -> Result<(), String> {
    let database = state.database.lock().await;
    database.execute(
        "INSERT OR IGNORE INTO envelopes (id, sender_device_id, recipient_device_id, payload) VALUES (?1, ?2, ?3, ?4)",
        params![envelope.id, envelope.sender_device_id, envelope.recipient_device_id, payload],
    ).map_err(|_| "Failed to store envelope".to_string())?;
    Ok(())
}

async fn deliver_envelope(state: &SharedState, envelope: &Envelope) -> Result<(), String> {
    let connection = {
        let connections = state.connections.lock().await;
        connections.get(&envelope.recipient_device_id).cloned()
    };
    if let Some(connection) = connection {
        let serialized = serde_json::to_string(&ServerMessage::Envelope { envelope: envelope.clone() })
            .map_err(|_| "Failed to serialize envelope".to_string())?;
        connection.send(Message::Text(serialized.into()))
            .map_err(|_| "Recipient connection is unavailable".to_string())?;
        info!("Envelope delivered to authenticated device: {}", envelope.recipient_device_id);
    } else {
        info!("Recipient offline; envelope persisted for device: {}", envelope.recipient_device_id);
    }
    Ok(())
}

async fn load_pending_envelopes(state: &SharedState, recipient_device_id: &str) -> Vec<Envelope> {
    let database = state.database.lock().await;
    let mut statement = match database.prepare(
        "SELECT id, sender_device_id, recipient_device_id, payload FROM envelopes WHERE recipient_device_id = ?1 ORDER BY created_at ASC",
    ) {
        Ok(statement) => statement,
        Err(error) => {
            error!("Failed to prepare pending envelope query: {error}");
            return Vec::new();
        }
    };
    let rows = match statement.query_map(params![recipient_device_id], |row| {
        let payload: Vec<u8> = row.get(3)?;
        Ok(Envelope {
            id: row.get(0)?,
            sender_device_id: row.get(1)?,
            recipient_device_id: row.get(2)?,
            payload: BASE64.encode(payload),
        })
    }) {
        Ok(rows) => rows,
        Err(error) => {
            error!("Failed to load pending envelopes: {error}");
            return Vec::new();
        }
    };
    rows.filter_map(|row| match row {
        Ok(envelope) => Some(envelope),
        Err(error) => {
            error!("Failed to read pending envelope: {error}");
            None
        }
    }).collect()
}

async fn acknowledge_envelope(state: &SharedState, connected_device_id: &str, envelope_id: &str) -> Result<(), String> {
    let database = state.database.lock().await;
    database.execute(
        "DELETE FROM envelopes WHERE id = ?1 AND recipient_device_id = ?2",
        params![envelope_id, connected_device_id],
    ).map_err(|_| "Failed to acknowledge envelope".to_string())?;
    Ok(())
}

fn initialize_database(database: &Connection) -> Result<(), rusqlite::Error> {
    database.execute_batch(
        "CREATE TABLE IF NOT EXISTS envelopes (
            id TEXT PRIMARY KEY,
            sender_device_id TEXT NOT NULL,
            recipient_device_id TEXT NOT NULL,
            payload BLOB NOT NULL,
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX IF NOT EXISTS idx_envelopes_recipient ON envelopes(recipient_device_id, created_at);
        CREATE TABLE IF NOT EXISTS device_bindings (
            device_id TEXT PRIMARY KEY,
            signing_public_key BLOB NOT NULL,
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        );",
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use ed25519_dalek::{Signer, SigningKey};

    #[test]
    fn relay_challenge_signature_verifies() {
        let signing_key = SigningKey::from_bytes(&[7u8; 32]);
        let device_id = "device-test";
        let nonce = "nonce-test";
        let payload = format!("MEYA relay authentication v1\n{device_id}\n{nonce}");
        let signature = signing_key.sign(payload.as_bytes());
        verify_signature(
            &signing_key.verifying_key().to_bytes(),
            &payload,
            &BASE64.encode(signature.to_bytes()),
        ).expect("signature should verify");
    }

    #[test]
    fn relay_challenge_rejects_wrong_payload() {
        let signing_key = SigningKey::from_bytes(&[7u8; 32]);
        let signature = signing_key.sign(b"different payload");
        let result = verify_signature(
            &signing_key.verifying_key().to_bytes(),
            "MEYA relay authentication v1\ndevice-test\nnonce-test",
            &BASE64.encode(signature.to_bytes()),
        );
        assert!(result.is_err());
    }
}
