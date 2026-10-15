use base64::{engine::general_purpose::STANDARD as BASE64, Engine as _};
use ed25519_dalek::{Signer, SigningKey};
use futures_util::{SinkExt, StreamExt};
use serde_json::{json, Value};
use tokio_tungstenite::{connect_async, tungstenite::Message};
use uuid::Uuid;

async fn receive_json(socket: &mut tokio_tungstenite::WebSocketStream<tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>>) -> Value {
    let frame = socket.next().await.expect("Relay closed connection").expect("Failed to receive relay response");
    let text = match frame {
        Message::Text(text) => text.to_string(),
        other => panic!("Expected a text response, received {other:?}"),
    };
    serde_json::from_str(&text).expect("Relay returned invalid JSON")
}

#[tokio::main]
async fn main() {
    let device_id = format!("meya-smoke-{}", Uuid::new_v4());
    let relay_url = format!("ws://127.0.0.1:8787/v1/ws?device_id={device_id}");
    println!("Connecting authenticated MEYA relay smoke test...");

    let (mut socket, _) = connect_async(&relay_url).await.expect("Failed to connect to MEYA relay");
    let challenge = receive_json(&mut socket).await;
    assert_eq!(challenge["type"], "Challenge", "Relay did not issue an authentication challenge");
    assert_eq!(challenge["device_id"], device_id);
    let nonce = challenge["nonce"].as_str().expect("Challenge nonce is missing");
    let registration_required = challenge["registration_required"].as_bool().expect("Registration flag is missing");

    let signing_key = SigningKey::from_bytes(&[7u8; 32]);
    let public_key = BASE64.encode(signing_key.verifying_key().to_bytes());
    let payload = format!("MEYA relay authentication v1\n{device_id}\n{nonce}");
    let signature = BASE64.encode(signing_key.sign(payload.as_bytes()).to_bytes());
    let auth_message = if registration_required {
        json!({"type": "Register", "public_key": public_key, "signature": signature})
    } else {
        json!({"type": "Authenticate", "signature": signature})
    };
    socket.send(Message::Text(auth_message.to_string().into())).await.expect("Failed to send authentication response");

    let authenticated = receive_json(&mut socket).await;
    assert_eq!(authenticated["type"], "Authenticated", "Relay did not authenticate the device");
    assert_eq!(authenticated["device_id"], device_id);

    let envelope = json!({
        "type": "Send",
        "envelope": {
            "id": format!("{device_id}-smoke-envelope"),
            "sender_device_id": device_id,
            "recipient_device_id": "meya-smoke-offline-recipient",
            "payload": BASE64.encode(b"MEYA relay authentication smoke test"),
        }
    });
    socket.send(Message::Text(envelope.to_string().into())).await.expect("Failed to send authenticated envelope");
    println!("PASS: challenge verified, device authenticated, and envelope accepted by relay.");
}
