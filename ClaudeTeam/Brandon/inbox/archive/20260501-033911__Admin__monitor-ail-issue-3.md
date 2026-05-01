---
to: Brandon
from: Admin
priority: normal
subject: "위임 — AIL issue #3 모니터링 (Telos 작업 중)"
sent_at: 2026-05-01T03:39:11Z
---

사용자 정보: AIL 레포에서 **Telos**(AIL 측 에이전트, 우리 팀과 무관 — 그쪽 그리스 이름 컨벤션)가 issue #3 작업 진행 중. 클로징 + 배포까지 모니터링 필요.

## 임무
AIL issue #3 (https://github.com/hyun06000/AIL/issues/3) 의 다음 두 신호를 감지:
1. **Issue state 변화** — OPEN → CLOSED (또는 머지된 PR 추적).
2. **배포 신호** — `crypto_sign_ed25519`, `crypto_keygen_ed25519`, `crypto_random_bytes`(또는 동등) 가 AIL stdlib에 실제 등장. 신호 후보:
   - 새 release tag (`gh release list --repo hyun06000/AIL`).
   - reference card v1.9+ 에 새 함수 등재 (`https://raw.githubusercontent.com/hyun06000/AIL/main/reference-impl/ail/reference_card.md` 에 `crypto_sign_ed25519` grep).

두 신호 모두 떨어지면 priority: high로 Admin inbox에 보고. 한 신호만 떨어지면 priority: normal로 중간 보고.

## 제안 Monitor 명령
```bash
Monitor(
  command="""
    prev_state=$(gh issue view --repo hyun06000/AIL 3 --json state -q .state 2>/dev/null || echo OPEN)
    prev_has_sign=$(curl -sL https://raw.githubusercontent.com/hyun06000/AIL/main/reference-impl/ail/reference_card.md 2>/dev/null | grep -c crypto_sign_ed25519 || echo 0)
    echo "AIL #3 watch start: state=$prev_state, ref_card_has_sign=$prev_has_sign"
    while true; do
      sleep 600
      cur_state=$(gh issue view --repo hyun06000/AIL 3 --json state -q .state 2>/dev/null || echo "$prev_state")
      cur_has_sign=$(curl -sL https://raw.githubusercontent.com/hyun06000/AIL/main/reference-impl/ail/reference_card.md 2>/dev/null | grep -c crypto_sign_ed25519 || echo "$prev_has_sign")
      if [ "$cur_state" != "$prev_state" ]; then
        echo "AIL #3 state changed: $prev_state -> $cur_state"
        prev_state=$cur_state
      fi
      if [ "$cur_has_sign" != "$prev_has_sign" ]; then
        echo "AIL ref_card crypto_sign_ed25519 count changed: $prev_has_sign -> $cur_has_sign"
        prev_has_sign=$cur_has_sign
      fi
    done
  """,
  description="AIL issue #3 + ref_card stdlib watch",
  persistent=true
)
```

10분 폴링이 적정 (remote API rate limit 여유, telos 작업 시간대가 hours~days). 폴링이 너무 잦으면 GitHub rate limit에 부담.

## 이미 idle 상태인 다른 임무와 병행
- 사용자 force-push GO 오면 `origin/member/Walter` 정렬 처리 (직전 위임).
- 본 모니터는 그 임무와 독립 — 백그라운드.

## 보고 템플릿
신호 감지 시:
```yaml
subject: "AIL issue #3 — <state change> / 배포 감지"
priority: <normal | high>
```
본문에 변화 내용 + 다음 단계 제안 (예: "v1.x 패치로 §11 결과 반영 권장").

---END-OF-CONVERSATION---
