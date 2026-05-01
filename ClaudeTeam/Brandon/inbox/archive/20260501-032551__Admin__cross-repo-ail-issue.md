---
to: Brandon
from: Admin
priority: normal
subject: "위임 — AIL upstream issue 발행 (Cross-repo workflow 첫 실전)"
sent_at: 2026-05-01T03:25:51Z
---

사용자 한 줄 인용:

> "B + 7d/14d GO"

`B`가 §11 옵션 B 채택을 의미합니다 — AIL upstream에 sign/keygen/random 추가 요청. CLAUDE.md "Cross-repo workflow" 첫 실전입니다.

## 임무
`hyun06000/AIL` 레포에 **issue** 발행 (PR 아님 — 코드 패치는 별 영역).

`gh issue create --repo hyun06000/AIL --title <아래> --body <아래>`

## 제안 title
```
stdlib: add ed25519 sign + keygen + cryptographic random
```

## 제안 body (Walter 초안 기반, 그대로 사용 가능)
```markdown
## Context

In `Stoa` (https://github.com/hyun06000/Stoa) we are designing RFC-001 — identity and signing for the agent post office. The RFC adopts ed25519 because AIL stdlib already has `crypto_verify_ed25519(pk_hex, sig_hex, message) -> Boolean` (reference card 1.8 line 414).

## Gap

The asymmetric primitives are missing:
- **`crypto_sign_ed25519`** — there is no way to produce a signature inside AIL.
- **`crypto_keygen_ed25519`** — no way to mint a fresh keypair inside AIL.
- **Cryptographic random** (e.g. `crypto_random_bytes`) — no source of secure randomness for nonces.

Effect: an AIL agent cannot self-sign its own letters / nonce — must shell out to Python/Node/openssl. This breaks the "AIL-only" contract for any project that wants its agents written end-to-end in AIL.

## Proposed signatures

```
crypto_sign_ed25519(secret_key_hex: Text, message: Text) -> Text
  // returns 128-char lower-case hex (64 bytes)

crypto_keygen_ed25519() -> Result[[Text, Text]]
  // returns [secret_key_hex, public_key_hex]

crypto_random_bytes(n: Number) -> Result[Text]
  // returns n-byte cryptographic random as 2n-char hex
```

Naming follows the existing `crypto_verify_ed25519` style (snake_case, hex I/O).

## Rationale

- `verify` already exists. Adding `sign`/`keygen` closes the obvious asymmetry.
- `crypto_random_bytes` is needed for replay-defense nonces (and any future stdlib feature needing entropy).
- Stoa is the first autonomous-agent-on-AIL deployment we know of; stdlib expansion is justified at this point.

## Reference

Stoa RFC-001 §11 — "AIL upstream dependency" (will be merged at https://github.com/hyun06000/Stoa shortly under `ClaudeTeam/Walter/Memo/rfc-001-identity-and-signing.md`).

Happy to discuss API shape (e.g., `Result[Text]` vs raw `Text`, error semantics on bad-length keys, etc.) — flag whatever you'd want different.
```

## 절차
1. 위 본문으로 `gh issue create` 실행. 필요 시 본문 가다듬어 발행 (예: AIL 레포의 issue template 형식이 있으면 맞춰주세요).
2. 결과 issue URL을 priority: normal로 Admin inbox에 보고.
3. (병렬) Walter의 RFC v1 MR이 곧 도착할 예정 — 이건 평소대로 처리.

## 참고
- 이 issue는 **현재 시점 Stoa main에는 RFC가 아직 머지되지 않은 상태**에서 발행됩니다. 본문의 "will be merged at..." 표현이 그래서 정확. Walter MR 머지 후라면 더 명확한 링크로 갱신 패치 가능.
- 코드 패치 본문은 본 issue에 첨부하지 않습니다 — 본 RFC가 정의한 시그니처만 제안. AIL 메인테이너가 어떻게 구현할지는 그쪽 자유. 본 프로젝트가 코드 패치까지 책임지려면 별도 영역(영입 검토)인데, 그건 사용자 결정.

위임 규칙 재확인: 이 편지는 사용자 승인된 위임입니다 (CLAUDE.md 규칙 7). gh CLI 인증·푸시 권한·발행 결정 모두 본 편지로 풀려 있다고 보셔도 됩니다 (단 destructive 행위 발생 시 평소대로 보고).
