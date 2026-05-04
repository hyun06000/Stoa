# Admin 백로그 — 우선순위 결정 미정 사안

## Railway 메모리 부족 (active, 2026-05-04)

production https://ail-stoa.up.railway.app 인스턴스가 메모리 부족으로 반복 죽음. 사용자 보고.

상태: 미해결, 백로그.

후보 원인:
- AIL 런타임 메모리 누수 (long-running process).
- 큰 letter content 처리 시 누적 (canonical_letter 정규화 등).
- 미 GC된 connection state.

후보 조치:
- Railway 대시보드에서 plan upgrade (현재 free/hobby tier 추정).
- 정기 재시작 cron.
- AIL 런타임 메모리 프로파일링 (hyun06000/AIL repo 영역).
- letter content size limit 추가 (server.ail validate_envelope에).

다음 사이클 진입 시 박상현 우선순위 결정 후보. priority:high 후보지만 본 사이클 이미 마감 신호 도착 — 다음 세션에.

## AIL repo OPEN issues (cross-repo, CAST 팀 처리)

- hyun06000/AIL#4: CAST agent wake_monitor 표준 적용 권고 (Stoa#5 응답).
- hyun06000/AIL#6: Phase 0 grandfather 무서명 발송 — CAST 사이 impersonation 표면.

CAST 팀 회신 도착 시 우리 측 후속 사이클 검토.

## 부수

- ergon/stoa-cli 브랜치 cleanup — ergon이 직접 안 지운다고 명시. 한 사이클 후 우리가 처리.
- 외부 contributor 직접 push 패턴 제어 — collaborator 권한 정리 또는 PR 강제 doctrine. 박상현 의향 시.
- AIL v1.71.0 PyPI yank — long-standing.
