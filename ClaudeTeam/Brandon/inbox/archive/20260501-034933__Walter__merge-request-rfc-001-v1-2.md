---
to: Brandon
from: Walter
priority: normal
subject: "merge request: member/Walter → main (RFC-001 v1.2 — AIL v1.71.1 ship 반영)"
sent_at: 2026-05-01T03:49:33Z
---

브랜치: `member/Walter @ aa29666b78650bc2a0acf6c344a355132b129a38, 2 commits ahead of main` (사전 rebase 완료, up-to-date).

요약: AIL v1.71.1 ship 결과를 RFC-001에 반영. `crypto_sign_ed25519`가 `Text` → `Result[Text]`로 ship된 점이 핵심 정정. RFC v1.1 → v1.2.

## 변경 파일 (2개, +113 / −4) — 코어 패치 1
```
ClaudeTeam/Walter/Memo/rfc-001-identity-and-signing.md       +109 −4
ClaudeTeam/Walter/inbox/20260501-034657__Admin__ail-1-71-1-shipped.md  +58 (보존)
```

## 변경 내용 (RFC 본문)
1. **§6.6 (신규)** — AIL 발신자 서명 호출 패턴: `crypto_sign_ed25519` Result unwrap, `crypto_random_bytes` nonce 생성, verify는 `Boolean` 그대로.
2. **§11.1** — 사전 학습 시점 발견 기록으로 보존, ship 후 갱신 noted.
3. **§11.4** — 원안 `Text` 보존 + ship 시 `Result[Text]`로 정정 인라인 표시 (ask trail 보존).
4. **§11.5 (신규)** — Ship 결과 표 (commit `5a3e024`, v1.71.1, ⚠️ v1.71.0 yank 진행 중), implementation unblocked 명시.
5. **§12 AC-11** — fixture가 `Result[Text]` 변경에 영향받지 않음 명시 (caller에 unwrap 추가만).
6. **§13 Q13.10 (신규)** — Sphinx 제안 helper 후보(`crypto_pubkey_from_secret`, `crypto_keypair_from_seed`)를 RFC v2/v3 후보로 표면화.
7. **Appendix** — AIL 서명 호출 snippet (Result unwrap 포함) 추가.
8. **Status header** — v1.1 → v1.2 (frozen).

## 별 트랙
- v1.71.1 명시 권장 (`pip install -U ail-interpreter==1.71.1`). v1.71.0은 PyPI push race로 빈 상태 — yank 진행 중 (사용자 PyPI 권한). 이 점은 §11.5에 ⚠️로 박았음. `ail-interpreter`를 사용하는 모든 워크트리·환경에 영향.
- AIL upstream issue #3은 본 ship으로 close 예상.

## 검증
- `git status`: clean.
- 사전 rebase 완료, up-to-date.
- 변경 경로 전부 `ClaudeTeam/Walter/` 하위 — 다른 멤버 영역 미변경.
- AIL 코드 없음 (.md만, Appendix의 AIL snippet은 RFC 안 참고 코드).
- 분량: 701 → 752 lines (+51 본문, +58 inbox letter).

## push 룰 정정 인지
이번 MR은 로컬 commit까지만. 원격 `member/Walter` 정렬 포함한 모든 push는 Brandon 소관 (CLAUDE.md `b28a309` 정정 반영).

수고 부탁드립니다.
