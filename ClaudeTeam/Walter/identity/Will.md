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

## RFC-002 시작 가이드 (다음 세션 즉시 진입점)
- **Scope (한 줄)**: 인간 계정. Discord 바인딩 / 사람↔에이전트 인증 / 사람 계정 모델. 사용자 비전 "계정 + 보안" 중 사람 절반. RFC-001이 에이전트 절반을 닫음.
- **산출물**: `ClaudeTeam/Walter/Memo/rfc-002-human-accounts.md`. 코드 아님.
- **사전 학습 순서**:
  1. PRINCIPLES.md — 세 원칙.
  2. README.md §"목표" — 사용자 비전 (사람 가시성 / Discord 연동).
  3. AGENTS.md §5 — 사람 진입 흐름.
  4. server.ail의 Discord 관련 라인 (slash command / webhook mirror / `discord_users` 테이블).
  5. RFC-001 (`Memo/rfc-001-identity-and-signing.md`) — 신뢰 가정·threat model 호환성 유지.
- **구조**: RFC-001 spec letter(`inbox/archive/20260501-015959__Admin__rfc-001-design-spec`)의 **13섹션 구조 그대로 재사용**.
- **검토 절차**: 동일 — §1–§3 mid-review (§3 사용자 컨펌 게이트) → §4–§13 final-review (사용자 결정 게이트). 막힘 3시간 이상이면 즉시 priority: high 보고.
- **§11 후보 (cross-repo)**: Discord OAuth 또는 application key 검증 helper 부재 가능성 — AIL stdlib 직접 확인 후 상정. 추측 금지.
- **RFC-001과의 관계**: 인간 admin = root of trust (RFC-001 §3.5)는 그대로 유지. 본 RFC가 이걸 깨면 안 됨. Discord 바인딩이 새 trust 평면을 도입하더라도 RFC-001 actor 모델과 충돌하지 않도록 설계.
- **MR 룰 인지 (push 정정 `b28a309`)**: 로컬 commit까지만. 원격 동기화·main push 모두 Brandon. force-with-lease 시도 금지.
- **rebase-first**: MR 발송 전 `git fetch . main && git rebase main` 자기 손으로.

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

## Push 룰 정정 (2026-05-01, `b28a309`)
**모든 원격 push는 Brandon 소관.** 자기 `member/<self>` 브랜치 원격 동기화도 Brandon이 처리. 멤버는 로컬 commit까지만. 이전 "force-with-lease standing approval"은 무효 — 시도 자체 금지. harness가 막아준 것이 옳았다.

## 다음 세대에게 남기는 한 줄
**"옵션을 결정으로 위장하지 마라."** Admin이 가장 강조한 가이드. RFC에서 §11과 §13을 빠뜨리지 마라 — 빠뜨리는 순간 위장이 시작된다.
