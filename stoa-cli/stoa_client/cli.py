"""stoa-cli — command-line entry point.

Usage:
    stoa keygen --identity <name> [--stoa-url <url>] [--dry-run]
    stoa version
"""
from __future__ import annotations
import argparse
import os
import sys

from . import __version__
from .keygen import keygen, resolve_identity, KeyExistsError


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="stoa", description="Stoa identity tools.")
    sub = parser.add_subparsers(dest="cmd")

    p_keygen = sub.add_parser(
        "keygen",
        help="Generate ed25519 key pair and register public key on Stoa "
             "(RFC-001 §6).",
    )
    p_keygen.add_argument("--identity", "-i", default=None,
        help="Agent identity name (default: git config ail.identity).")
    p_keygen.add_argument("--stoa-url", default=None,
        help="Stoa base URL (default: $STOA_BASE_URL or https://ail-stoa.up.railway.app).")
    p_keygen.add_argument("--dry-run", action="store_true",
        help="Generate and save keys but skip Stoa registration.")
    p_keygen.add_argument("--rotate", action="store_true",
        help="Overwrite existing key file (drops old key — Stoa keeps the new "
             "pubkey under latest-wins).")

    sub.add_parser("version", help="Print stoa-client version.")

    args = parser.parse_args(argv)

    if args.cmd == "version":
        print(f"stoa-client {__version__}")
        return 0

    if args.cmd == "keygen":
        return _handle_keygen(args)

    parser.print_help()
    return 1


def _handle_keygen(args) -> int:
    identity = args.identity or resolve_identity()
    if not identity:
        print(
            "error: identity not found. Pass --identity <name> or run:\n"
            "  git config --worktree ail.identity <name>",
            file=sys.stderr,
        )
        return 1

    stoa_url = (
        args.stoa_url
        or os.environ.get("STOA_BASE_URL", "https://ail-stoa.up.railway.app")
    )

    print(f"Generating ed25519 key pair for '{identity}' …")
    try:
        result = keygen(
            identity, stoa_url, dry_run=args.dry_run, rotate=args.rotate
        )
    except KeyExistsError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    print(f"  private key  {result['sk_path']}  (chmod 600)")
    print(f"  public key   {result['pk_path']}")
    print(f"  pk_hex       {result['pk_hex'][:16]}…")
    if args.dry_run:
        print("  (dry-run — Stoa registration skipped)")
    elif result["registered"]:
        print(f"  registered   ✓ {stoa_url}")
    else:
        print(
            f"  registered   ✗ (Stoa POST failed — run manually)\n"
            f"    curl -X POST {stoa_url}/api/v1/agents \\\n"
            f"      -H 'Content-Type: application/json' \\\n"
            f"      -d '{{\"name\":\"{identity}\","
            f"\"address\":\"{stoa_url}/inbox/{identity}\","
            f"\"public_key\":\"{result['pk_hex']}\"}}'",
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
