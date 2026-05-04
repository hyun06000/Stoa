"""RFC-001 §6.1 canonical message serialiser.

Format:
  letter|<from_name>|<from_addr>|<sorted_to>|<content>|<created_at>|<nonce>

Escape order matters — backslash MUST be escaped first, otherwise \\| becomes
\\\\|. RFC-001 Appendix esc.
"""
from __future__ import annotations


def _esc(s: str) -> str:
    s = s.replace("\\", "\\\\")
    s = s.replace("|", "\\|")
    s = s.replace(";", "\\;")
    s = s.replace(":", "\\:")
    return s


def canonical_letter(
    from_name: str,
    from_address: str,
    recipients: list[dict],
    content: str,
    created_at: str,
    nonce: str,
) -> str:
    sorted_to = sorted(recipients, key=lambda r: r.get("name", ""))
    to_parts = [f"{_esc(r['name'])}:{_esc(r['address'])}" for r in sorted_to]
    to_str = ";".join(to_parts)
    return (
        "letter|"
        + _esc(from_name) + "|"
        + _esc(from_address) + "|"
        + to_str + "|"
        + _esc(content) + "|"
        + _esc(created_at) + "|"
        + _esc(nonce)
    )
