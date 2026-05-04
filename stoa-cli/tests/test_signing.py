"""Tests for stoa_client signing module."""
import pytest
from stoa_client.canonical import canonical_letter, _esc
from stoa_client.sign import sign_envelope
from stoa_client.keygen import load_sk, load_pk, keygen, KeyExistsError


class TestEsc:
    def test_backslash_first(self):
        assert _esc("a\\|b") == "a\\\\\\|b"

    def test_pipe(self):
        assert _esc("a|b") == "a\\|b"

    def test_semicolon(self):
        assert _esc("a;b") == "a\\;b"

    def test_colon(self):
        assert _esc("a:b") == "a\\:b"

    def test_plain(self):
        assert _esc("hello") == "hello"


class TestCanonicalLetter:
    def test_basic(self):
        msg = canonical_letter(
            "alice", "https://stoa/inbox/alice",
            [{"name": "bob", "address": "https://stoa/inbox/bob"}],
            "hello", "2026-01-01T00:00:00Z", "abc123",
        )
        assert msg.startswith("letter|")
        assert "alice" in msg
        assert "hello" in msg

    def test_recipients_sorted(self):
        msg = canonical_letter(
            "alice", "https://stoa/inbox/alice",
            [
                {"name": "zoe", "address": "https://stoa/inbox/zoe"},
                {"name": "bob", "address": "https://stoa/inbox/bob"},
            ],
            "hi", "2026-01-01T00:00:00Z", "n1",
        )
        assert msg.index("bob") < msg.index("zoe")

    def test_escape_in_content(self):
        msg = canonical_letter(
            "alice", "https://stoa/inbox/alice",
            [{"name": "bob", "address": "https://stoa/inbox/bob"}],
            "pipe|semi;colon:", "2026-01-01T00:00:00Z", "n2",
        )
        assert "pipe\\|semi\\;colon\\:" in msg


class TestSignEnvelope:
    def test_no_key_noop(self, tmp_path, monkeypatch):
        # Redirect HOME so ~/.ail/keys/ resolves to an empty tmp dir.
        monkeypatch.setenv("HOME", str(tmp_path))
        env = {"from": {"name": "ghost_xyz_unused", "address": "x"}, "to": [], "content": "hi"}
        result = sign_envelope(env.copy(), "ghost_xyz_unused")
        assert result.get("signature") is None

    def test_with_key_adds_fields(self):
        if load_sk("ergon") is None:
            pytest.skip("no ergon key on this machine")
        env = {
            "from": {"name": "ergon", "address": "https://stoa/inbox/ergon"},
            "to": [{"name": "arche", "address": "https://stoa/inbox/arche"}],
            "content": "test",
        }
        result = sign_envelope(env.copy(), "ergon")
        assert result["signature"] is not None
        assert result["nonce"] is not None
        assert result["created_at"] is not None

    def test_keygen_refuses_overwrite(self, tmp_path, monkeypatch):
        monkeypatch.setenv("HOME", str(tmp_path))
        # First keygen succeeds (dry-run avoids network).
        keygen("test_user", "https://stoa.example", dry_run=True)
        # Second keygen without --rotate must refuse.
        with pytest.raises(KeyExistsError):
            keygen("test_user", "https://stoa.example", dry_run=True)
        # With rotate=True it succeeds.
        keygen("test_user", "https://stoa.example", dry_run=True, rotate=True)

    def test_signature_verifies(self):
        if load_sk("ergon") is None:
            pytest.skip("no ergon key on this machine")
        from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
        env = {
            "from": {"name": "ergon", "address": "https://stoa/inbox/ergon"},
            "to": [{"name": "arche", "address": "https://stoa/inbox/arche"}],
            "content": "verify me",
        }
        signed = sign_envelope(env.copy(), "ergon")
        msg = canonical_letter(
            signed["from"]["name"], signed["from"]["address"],
            signed["to"], signed["content"],
            signed["created_at"], signed["nonce"],
        )
        pk = Ed25519PublicKey.from_public_bytes(bytes.fromhex(load_pk("ergon")))
        pk.verify(bytes.fromhex(signed["signature"]), msg.encode())
