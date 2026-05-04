"""stoa-client — Stoa identity helpers (RFC-001 §6 ed25519 keygen + signing).

Public API:
    keygen(identity, stoa_url, dry_run) -> dict
    sign_envelope(envelope, identity) -> dict
    canonical_letter(...) -> str
    load_sk(identity) -> str | None
    load_pk(identity) -> str | None
    resolve_identity() -> str | None

CLI:
    stoa keygen --identity <name>
"""
from .canonical import canonical_letter, _esc
from .keygen import keygen, key_path, keys_dir, load_sk, load_pk, resolve_identity
from .sign import sign_envelope

__version__ = "0.1.0"
__all__ = [
    "canonical_letter",
    "keygen",
    "key_path",
    "keys_dir",
    "load_sk",
    "load_pk",
    "resolve_identity",
    "sign_envelope",
    "__version__",
]
