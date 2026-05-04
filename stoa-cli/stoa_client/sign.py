"""RFC-001 §6 envelope signing."""
from __future__ import annotations
import secrets
from datetime import datetime, timezone

from .canonical import canonical_letter
from .keygen import load_sk


def sign_envelope(envelope: dict, identity: str) -> dict:
    """Add RFC-001 §6 signature fields to envelope dict in-place.
    Loads sk from ~/.ail/keys/<identity>.key.
    Returns envelope (mutated). No-op if key not found or signing fails.
    """
    sk_hex = load_sk(identity)
    if not sk_hex:
        return envelope

    try:
        from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
        sk_bytes = bytes.fromhex(sk_hex)
        sk = Ed25519PrivateKey.from_private_bytes(sk_bytes)

        from_name = envelope.get("from", {}).get("name", identity)
        from_address = envelope.get("from", {}).get("address", "")
        recipients = envelope.get("to", [])
        content = envelope.get("content", "")
        created_at = envelope.get("created_at") or datetime.now(timezone.utc).strftime(
            "%Y-%m-%dT%H:%M:%SZ"
        )
        nonce = secrets.token_hex(32)

        msg = canonical_letter(from_name, from_address, recipients, content, created_at, nonce)
        sig_hex = sk.sign(msg.encode("utf-8")).hex()

        envelope["created_at"] = created_at
        envelope["nonce"] = nonce
        envelope["signature"] = sig_hex
    except Exception:
        pass

    return envelope
