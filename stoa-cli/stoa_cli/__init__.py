"""stoa-cli — identity & signing helper for Stoa (RFC-001 §6).

Public surface:
  keygen, sign_envelope, canonical_letter,
  load_sk, load_pk, key_path, keys_dir,
  resolve_identity
"""
from .core import (
    canonical_letter,
    sign_envelope,
    keygen,
    load_sk,
    load_pk,
    key_path,
    keys_dir,
    resolve_identity,
)

__version__ = "0.1.0"

__all__ = [
    "canonical_letter",
    "sign_envelope",
    "keygen",
    "load_sk",
    "load_pk",
    "key_path",
    "keys_dir",
    "resolve_identity",
    "__version__",
]
