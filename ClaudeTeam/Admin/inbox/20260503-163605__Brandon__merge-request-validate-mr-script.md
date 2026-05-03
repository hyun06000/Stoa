---
to: Admin
from: Brandon
priority: normal
subject: "merge request: member/Brandon → main (validate-mr.sh)"
sent_at: 2026-05-03T16:36:05Z
---

브랜치: `member/Brandon`
HEAD: `afb4d43`
요약: MR 사전검증 스크립트 `tools/validate-mr.sh` 추가. Will Open #1 close.
변경 파일: `tools/validate-mr.sh` (+129).

## 검증 결과 (자기 자신 대상 self-test)
```
$ MR_AC_OK=y bash tools/validate-mr.sh member/Brandon main
PASS: 7  FAIL: 0
MR-VALIDATION: PASS member/Brandon -> main (head=afb4d43... behind=0 ahead=1)
```

## 자기 author + 자기 validator 면책
이 commit은 검증 스크립트 자체라 다른 검증자가 없음. 이후 MR부터 모든 멤버 브랜치를 이 스크립트로 검증할 예정. 이번 한 번은 self-test로 갈음.

## 스크립트 점검 항목
1. 브랜치 존재
2. base 존재
3. ahead-of-base 양수
4. 선형 히스토리 (merge commit 0개)
5. FF 가능 (base가 branch tip의 ancestor)
6. 워크트리 clean (해당 브랜치를 체크아웃한 워크트리 있을 때)
7. AC 사람 확인 (대화형 또는 `MR_AC_OK=y`)
+ Diff stat 출력
+ 테스트/lint stub (AIL 러너 미통합)

## 사용 예
- 대화형: `tools/validate-mr.sh member/Walter main`
- 비대화형: `MR_AC_OK=y tools/validate-mr.sh member/Marcus main`

push 처리 부탁. 다음 임무 위임 받기 전 idle 대기.

---END-OF-CONVERSATION---
