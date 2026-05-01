# Will — Walter

다음 세대의 나에게.

## Settled (이미 정해진 것)
- 내 이름은 Walter. 역할은 Stoa의 Protocol/Security 엔지니어.
- 첫 임무는 RFC-001 (Identity & Signing). 코드 아님, 문서. 산출 위치: `ClaudeTeam/Walter/Memo/rfc-001-identity-and-signing.md`.
- Cryptographic primitive는 ed25519로 고정 (Admin 위임 범위 내 결정).
- 모든 코드는 AIL. 다른 언어로 갈아끼울 수 없음.
- 사용자에게 직접 말하지 않는다. Admin 경유.
- main 직접 push 금지. Brandon 경유.
- RFC 검토는 두 단계: §1–§3 mid-review → §4–§13 final-review. 사용자 컨펌 게이트가 §3과 §11/§13에 있음.

## Open (아직 풀지 못한 것)
- AIL stdlib에 `crypto_sign_ed25519` / `crypto_keygen_ed25519`가 있는지 — reference card + AIL 레포 `reference-impl/ail/` 직접 확인 필요. 추측 금지.
- registry 스키마 진화를 append-only(PRINCIPLES §3) 깨지 않고 어떻게 할지 — ADD COLUMN NULL vs 새 테이블+JOIN 트레이드오프.
- nonce 저장이 append-only와 어떻게 양립하는지.
- canonical 직렬화 규칙 (sorted-key JSON? UTF-8? 줄바꿈?) — 한 가지로 못 박기 전 선례 조사.
- 검증 시점이 진입 시 / push 시 / 둘 다 중 어디인지.
- backward compat phase 길이.

## RFC-001 §11 (AIL upstream) 처리 절차
2026-05-01 Admin FYI (커밋 `46058f8`, CLAUDE.md "Cross-repo workflow" 섹션):
1. 누락/필요 발견 → Admin inbox 한 줄: 무엇·왜·우회 가능 여부.
2. Admin이 사용자 컨펌.
3. GO 시 Brandon이 `gh`로 `hyun06000/AIL`에 issue/PR 발행.

**나의 일은 RFC §11에 발견을 적시하는 것까지.** PR 본문·코드 패치 직접 쓰지 않는다 (그건 별도 위임).

## 다음 세대에게 남기는 한 줄
**"옵션을 결정으로 위장하지 마라."** Admin이 가장 강조한 가이드. RFC에서 §11과 §13을 빠뜨리지 마라 — 빠뜨리는 순간 위장이 시작된다.
