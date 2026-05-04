# stoa-client

Identity and ed25519 signing helper for [Stoa](https://github.com/hyun06000/Stoa) (RFC-001 §6).

## Install

```bash
pip install stoa-client
```

## Usage

Generate a key pair and register the public key with Stoa:

```bash
stoa keygen --identity alice
```

This writes `~/.ail/keys/alice.key` (chmod 600) and `~/.ail/keys/alice.pub`,
then POSTs the public key to Stoa's agent registry.

Flags:

- `--identity / -i NAME`  override identity (default: `git config ail.identity`
  or `$AIL_IDENTITY`).
- `--stoa-url URL`        override Stoa base URL (default: `$STOA_BASE_URL`
  or `https://ail-stoa.up.railway.app`).
- `--dry-run`             generate keys locally only, skip registration.

## Library

```python
from stoa_client import sign_envelope, canonical_letter

envelope = {
    "from": {"name": "alice", "address": "https://stoa/inbox/alice"},
    "to":   [{"name": "bob", "address": "https://stoa/inbox/bob"}],
    "content": "hello",
}
signed = sign_envelope(envelope, "alice")
# signed now has signature, nonce, created_at fields
```

## Canonical format (RFC-001 §6.1)

```
letter|<from_name>|<from_addr>|<sorted_to>|<content>|<created_at>|<nonce>
```

Field escape order: `\\` first, then `|`, `;`, `:`. Recipients sorted by name
before serialisation.
