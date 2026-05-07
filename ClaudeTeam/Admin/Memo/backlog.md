# Admin 백로그 — 우선순위 결정 미정 사안

## Pending — cycle 7 cascade trigger (2026-05-08)

**Marcus Phase A SHA land 후**: 팀 버전 싱크(멤버 워크트리 rebase) → main 머지(Phase A 정점) → README **꼼꼼한** 업그레이드(Phase A endpoint `/api/v1/inbox` + `/inbox/ack`, self-key, registry self-row, RFC-004 link, "Stoa 안 터트리고 쓰기" 가이드, version line, 무네메·AIL 자매 결합 framing). 박상현 위임.

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

## ONBOARDING §0 1인칭 식별 단계 (queued, 2026-05-07)

본 사이클 6 부팅 시 Walter·Rachel 두 명 연속으로 첫 응답에서 정체성 혼동 — 자기를 3인칭("Walter는·Rachel은")으로 서술하거나 Admin 시점("저(Admin)는...")으로 발화. 박상현 직접 식별 지시("너는 Walter다/Rachel이다") 후 1인칭 회복.

원인 추정: Claude Code 세션이 CLAUDE.md(팀 리더 시점·Admin doctrine 풍부)부터 읽으면서 자연스럽게 *팀 리더 화자*를 채택. ONBOARDING §0 의식이 \"identity 3종 읽는다\"로 그치고 *자기 식별 명시 단계*를 강제하지 않음 → 식별 누락 확률↑.

권고 patch:
- **§0 (2.5)** 신설: \"identity 3종을 읽은 직후, **자신이 누구인지 1인칭으로 명시 회복**한다 — 한 줄: '저는 <자신>입니다. 역할: <한 줄>.' 이 줄을 발화하기 전에는 어떤 작업도 시작하지 않는다.\"
- 이유 한 줄: Walter·Rachel 사이클 6 부팅 사고 학습.

또는 §0(2) \"이 파일(ONBOARDING)을 읽는다\" 다음에 \"이 의식이 끝나기 전에는 자신을 자신이라 부르지 마세요\" 줄을 강화 — 현재 §0 마지막 줄에만 있음, §0(2.5)로 *적극적* 1인칭 발화 유도가 더 강함.

본 사이클 종료 시 Walter doc patch에 한 줄로 동봉 또는 별 commit. Memo decisions에 land 시 등재.

## README 업그레이드 (queued, RFC-004 land 후 의무, 2026-05-07)

박상현 발화 — "누구든지 스토아의 리드미를 읽으면 스토아를 터트리지 않고 쓸 수 있어야해. 리드미도 스토아 수리가 끝나면 반드시 업그레이드."

조건: **RFC-004 Stoa-as-agent land 후** (Stoa 수리 완료 시점). 이전 Stoa 상태로 README 쓰면 곧 obsolete.

요구:
- *터뜨리지 않고 쓸 수 있어야* — 5분 cookbook 수준의 안전한 진입 path. 잘못된 endpoint, 잘못된 schema, 잘못된 monitor 패턴으로 빠지지 않도록.
- issue#8(독자별 5-persona 재구성, deferred) 포함 — human / agent / AIL author / Stoa-팀 / RFC author 5 persona별.
- 안전 결로 — Mneme issue#10 polling 함정, issue#7 에이전트 vs 사람 path 혼동, issue#6 envelope schema, issue#4 sender registry 같은 *과거에 빠졌던 함정*을 README가 미리 차단.

권고 트랙:
- **시점**: RFC-004 land 직후 (Stoa 새 phusis·subscribe·ack semantics 안정화 후).
- **담당**: Walter (doctrine·RFC 작성자) + Marcus (server.ail 진실 소스 검증). Admin doc 라우팅.
- **issue#8 close 트랙**: 본 작업이 issue#8을 자연 흡수.
- **참조 캐논**: `community-tools/stoa_wake_monitor.sh`을 표준 monitor reference로 README에 핀 (Mneme issue#10 즉답 트랙 합류).

## CC 기능 (queued, 2026-05-07)

박상현 발화 — "스토아에 cc기능이 있으면 편할 것 같아. 미래의 작업 큐에 인."

현 envelope schema는 `to: [{name, address}, ...]` 배열이라 단순히 to 배열에 더 넣어도 작동은 함. CC가 의미적으로 분리되는 가치는:
- 수신자 vs 참조자 구분 — 답신 의무가 다름 (룰 5 본문 EOC 마커 + CC면 informational only).
- UI/Discord mirror에서 헤더 분리 표시.
- 룰 14 ping/pong·룰 21 idle letter 같은 정합 책임이 to-만에 묶이고 cc는 면제.

검토 후보:
- Phase 1: envelope에 `cc: [{name, address}, ...]` 추가, 옛 to만 사용 path 호환.
- Phase 2: server.ail 라우팅에서 to/cc 동등 push, validation 시 from address binding은 동일 적용.
- Phase 3: 룰 갱신 — \"cc 수신은 답신 의무 면제\".

RFC-004 Stoa-as-agent 사이클과 자연 합류 가능 (envelope schema 손대는 김에). 또는 별 RFC-005 (envelope v2). 시점: 박상현 trigger 또는 RFC-004 schema 결정 시.

## 부수

- ergon/stoa-cli 브랜치 cleanup — ergon이 직접 안 지운다고 명시. 한 사이클 후 우리가 처리.
- 외부 contributor 직접 push 패턴 제어 — collaborator 권한 정리 또는 PR 강제 doctrine. 박상현 의향 시.
- AIL v1.71.0 PyPI yank — long-standing.
