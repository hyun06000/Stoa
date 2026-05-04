"""ed25519 key generation, file I/O, Stoa registry registration."""
from __future__ import annotations
import json
import os
import urllib.request
from pathlib import Path


def keys_dir() -> Path:
    d = Path.home() / ".ail" / "keys"
    d.mkdir(parents=True, exist_ok=True)
    return d


def key_path(identity: str) -> tuple[Path, Path]:
    """Returns (sk_path, pk_path)."""
    d = keys_dir()
    return d / f"{identity}.key", d / f"{identity}.pub"


def load_sk(identity: str) -> str | None:
    sk_path, _ = key_path(identity)
    if not sk_path.exists():
        return None
    return sk_path.read_text().strip()


def load_pk(identity: str) -> str | None:
    _, pk_path = key_path(identity)
    if not pk_path.exists():
        return None
    return pk_path.read_text().strip()


class KeyExistsError(Exception):
    """Raised when a key file for this identity already exists and rotate=False."""


def keygen(
    identity: str,
    stoa_url: str,
    dry_run: bool = False,
    rotate: bool = False,
) -> dict:
    """Generate ed25519 key pair, save to ~/.ail/keys/, register public key
    on Stoa.  Returns {"pk_hex": ..., "sk_path": ..., "pk_path": ...,
    "registered": bool}.

    Raises KeyExistsError if ~/.ail/keys/<identity>.key already exists and
    rotate=False — overwriting drops the previously registered key with no
    way to re-sign for it.  Pass rotate=True to intentionally rotate (server
    keeps the new pubkey under latest-wins).
    """
    sk_path, pk_path = key_path(identity)
    if sk_path.exists() and not rotate:
        raise KeyExistsError(
            f"{sk_path} already exists. Pass --rotate to overwrite "
            f"(this drops the old key — the registered pubkey on Stoa will "
            f"be replaced with the new one)."
        )

    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

    sk = Ed25519PrivateKey.generate()
    pk = sk.public_key()

    sk_hex = sk.private_bytes_raw().hex()
    pk_hex = pk.public_bytes_raw().hex()

    sk_path.write_text(sk_hex + "\n")
    os.chmod(sk_path, 0o600)
    pk_path.write_text(pk_hex + "\n")
    os.chmod(pk_path, 0o644)

    registered = False
    if not dry_run and stoa_url:
        registered = _register_pubkey(stoa_url, identity, pk_hex)

    return {
        "pk_hex": pk_hex,
        "sk_path": str(sk_path),
        "pk_path": str(pk_path),
        "registered": registered,
    }


def _register_pubkey(stoa_url: str, identity: str, pk_hex: str) -> bool:
    base = stoa_url.rstrip("/")
    try:
        with urllib.request.urlopen(f"{base}/api/v1/agents/{identity}", timeout=8) as r:
            agent = json.loads(r.read())
        address = agent.get("address", f"{base}/inbox/{identity}")
    except Exception:
        address = f"{base}/inbox/{identity}"

    payload = json.dumps(
        {"name": identity, "address": address, "public_key": pk_hex}
    ).encode()
    req = urllib.request.Request(
        f"{base}/api/v1/agents",
        method="POST",
        data=payload,
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=8):
            pass
        return True
    except Exception:
        return False


def resolve_identity() -> str | None:
    """Return current agent identity from git config or env."""
    import subprocess
    for scope in (
        ["git", "config", "--worktree", "--get", "ail.identity"],
        ["git", "config", "--get", "ail.identity"],
    ):
        try:
            r = subprocess.run(scope, capture_output=True, text=True, timeout=3)
            if r.returncode == 0 and r.stdout.strip():
                return r.stdout.strip()
        except Exception:
            pass
    return os.environ.get("AIL_IDENTITY")
