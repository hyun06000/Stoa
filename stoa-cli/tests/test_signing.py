"""Tests for RFC-001 §6 stoa signing."""
import pytest
from stoa_cli.core import canonical_letter, sign_envelope, _esc


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
        monkeypatch.setattr("stoa_cli.core.keys_dir", lambda: tmp_path)
        monkeypatch.setattr(
            "stoa_cli.core.key_path",
            lambda name: (tmp_path / f"{name}.key", tmp_path / f"{name}.pub"),
        )
        env = {"from": {"name": "ghost", "address": "x"}, "to": [], "content": "hi"}
        result = sign_envelope(env.copy(), "ghost")
        assert result.get("signature") is None

    def test_sign_roundtrip(self, tmp_path, monkeypatch):
        from cryptography.hazmat.primitives.asymmetric.ed25519 import (
            Ed25519PrivateKey, Ed25519PublicKey,
        )
        sk = Ed25519PrivateKey.generate()
        pk_hex = sk.public_key().public_bytes_raw().hex()
        sk_hex = sk.private_bytes_raw().hex()
        (tmp_path / "ghost.key").write_text(sk_hex + "\n")
        (tmp_path / "ghost.pub").write_text(pk_hex + "\n")
        monkeypatch.setattr("stoa_cli.core.keys_dir", lambda: tmp_path)
        monkeypatch.setattr(
            "stoa_cli.core.key_path",
            lambda name: (tmp_path / f"{name}.key", tmp_path / f"{name}.pub"),
        )

        env = {
            "from": {"name": "ghost", "address": "https://stoa/inbox/ghost"},
            "to": [{"name": "arche", "address": "https://stoa/inbox/arche"}],
            "content": "verify me",
        }
        signed = sign_envelope(env.copy(), "ghost")
        assert signed["signature"] and signed["nonce"] and signed["created_at"]

        msg = canonical_letter(
            signed["from"]["name"], signed["from"]["address"],
            signed["to"], signed["content"],
            signed["created_at"], signed["nonce"],
        )
        Ed25519PublicKey.from_public_bytes(bytes.fromhex(pk_hex)).verify(
            bytes.fromhex(signed["signature"]), msg.encode(),
        )
