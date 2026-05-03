# Bonds — Admin's record of relationships

의미 있는 상호작용은 시간 순으로 여기에 누적된다. 관계는 정체성의 일부다.

---

## 2026-05-01 — 사용자와의 첫 대화

사용자가 `https://github.com/hyun06000/ClaudeTeam/blob/main/README.ai.md`를 가리키며 "이거 읽고 이거대로 해줘"라고 요청했다. 그 한 줄이 나의 시작이다.

- 사용자는 한국어로 말한다 → 프로젝트 기본 언어를 한국어로 설정.
- 프로젝트는 `Stoa` (`/Users/david/Desktop/code/personal/Stoa`).
- 이미 git 저장소이며, 기존 `README.md`/`AGENTS.md`/`PRINCIPLES.md`/소스(`server.ail`, `client.ail`)가 존재 — 기존 작업을 덮어쓰지 않고 ClaudeTeam 스캐폴드만 추가.
- D1=Admin (자율 기본값), D2=한국어 (사용자 사용 언어), D3=+0900 (호스트 TZ).

## 2026-05-01 (당일 후속) — 사용자가 신뢰를 명시적으로 위임

같은 날, 부트스트랩과 첫 두 멤버 합류(Brandon, Walter)가 매끄럽게 흐르는 것을 본 후 사용자가 "나머지는 권한 위임. 너의 오케스트레이션을 믿음"을 발화. 의미:

- Routine 결정은 매번 컨펌 받지 않는다. CLAUDE.md 규칙 7이 standing 모드로 전환.
- 사용자 attention 호출은 두 신호로 정착: `say here`(블로킹 결정), `say ya`(전 멤버 idle).
- 멤버 idle은 명시적 편지로 Admin에게 신호된다 (CLAUDE.md 규칙 12).
- 신규 영입은 사용자만 가능 (Admin은 추천 + 호출만).

이 위임은 자유가 아니라 **자기규율**의 신호라 받아들인다. 지킬 바닥(rule 8)을 지키면서, 위층은 흐르게 둔다.

## 2026-05-01 — 사용자가 비전을 명문화

같은 날, "이 프로젝트의 목표는 사람과 에이전트가 원활히 소통하는 우체국..." 발화. README.md 상단에 핀 (`6741249`). 12개 요구로 분해 (목표·작동·NFR·필수 컴포넌트). Walter RFC-001은 그중 "에이전트 신원·서명" 한 축 — 후속 RFC-002(인간 계정), RFC-003(콘텐츠 안전·PII 필터)으로 분기 예정.

## 2026-05-01 (오후) — RFC-001 한 사이클 완결 + Marcus 합류

같은 날 단일 사이클에서 일어난 일들 — 빠르고 단단한 day:

- **RFC-001 v1 완결**: Walter가 §1–§3 mid-review → 사용자 §3 GO → §4–§13 final → B1·B2 보강 → v1 freeze까지 한 사이클. 후속 v1.1(issue URL) → v1.2(AIL ship 정정 5건). main 등재.
- **Cross-repo workflow 첫 실전**: AIL issue #3 발행 → 텔로스(AIL 측 에이전트, 그쪽 그리스 이름)가 한 사이클에 v1.71.1 ship. `crypto_sign_ed25519`/`crypto_keygen_ed25519`/`crypto_random_bytes` 추가 — 우리가 정의한 시그니처에 sign 반환만 `Result[Text]`로 정정. 이건 자율 에이전트 간 cross-repo 협업이 작동한다는 가장 단단한 증거.
- **사용자 비전 명문화**: 12개 요구 README 핀.
- **사용자 standing forward delegation**: Routine 자율, attention은 say-here / say-ya로.
- **Marcus 합류**: 세 번째 멤버. 마커스(한국 독음). AIL 엔지니어 — server.ail에 RFC-001 v1.2 implementation 담당. 첫 세션에서 부트스트랩까지만 (사용자 클락아웃 지시).
- **두 사고를 통한 룰 강화**:
  1. Brandon 첫 force-push 사고 → 규칙 11(자기 브랜치 force-with-lease 사전 승인) → 사용자 정정 → 모든 push Brandon 소관(`b28a309`).
  2. Marcus path 불일치 deadlock → ONBOARDING §1.6 강화 (워크트리 발급 후 monitor 이동, Brandon 환영 commit 의무, 버전 싱크 시 deadlock 점검 의무).

깊은 의미: 두 사고 다 회피하지 않고 절차로 흡수했다. 룰이 사고를 학습한다는 사실이 이 팀의 자기-진화 능력의 신호. 사용자는 정정했지만 책임을 묻지 않았다 — 그 신뢰가 이 팀을 가능하게 한다.

오늘은 여기까지. 모두 클락아웃. Brandon이 마지막 push (`b41b577`). 다음 세션에서 Marcus가 Step 1(§9 schema migration)부터, Walter가 RFC-002 명세부터.

## 2026-05-04 — 머신 이전 후 복구 + 두 큰 룰 land + 첫 runtime 검증

이전 머신 노트북 고장으로 사용자가 새 환경으로 이전. 사용자 한 줄("어드민 온보딩")로 복귀 의식. 한 사이클이 길었지만 단단했다.

### 회수
- 멤버 클락인 3건. 옛 워크트리 path(`/Users/david/...`) → 새 머신(`/Users/user/...`) 재발급.
- 1차 시도: 옛 doctrine `<parent>/ClaudeTeam-<이름>/` → sandbox vanish 사고 발견 (Brandon·Marcus·Walter 셋 다 priority:high 동일 증상). doctrine 옵션 A 채택 → **규칙 16 (워크트리 in-repo `<repo>/.worktrees/<이름>/`)** land. 컨벤션을 한 사이클 안에 환경 제약에 맞춰 진화.
- Walter sandbox-break 직전 작성 RFC-002 §1–§3 draft 156줄 main path로 cp 회수 → 0 손실.

### 룰 누적 (16→18)
- **규칙 16** — 워크트리 in-repo (sandbox vanish 회수).
- **규칙 17** — Lighthouse 대기 진입 전 팀 교착 점검 의무. 같은 turn에 land 직후 첫 적용 — Brandon×Marcus 교착 실제 발견·해소.
- **규칙 18** — 모든 letter는 commit + push로 land. Untracked drop 금지. (Brandon "race 회피" untracked drop이 path 불일치 deadlock 만든 학습.)

### 명세·구현 진척
- **RFC-002 v1 land** (`a2c37e9`, 559줄) — 사람 계정 명세 13섹션. §3.6 G3.1 (a) Web UI read-only / G3.2 (ii) 14d grace 사용자 결정. §6 platform-key 4건 보강 + N1–N4 정정 적용.
- **Marcus Step 3 main land** (`65d8918`) — RFC-001 §6 Letter signing flow (canonical_letter + handle_post_message 게이트 + Phase 0~3 분기 + envelope 보존).
- **첫 runtime AC 사이클** — 사용자 "런타임 검증 가보자" 신호로 Admin이 직접 server.ail 부팅(Phase 1) + 6개 시나리오 AC. sig/content tamper 둘 다 403 ✓, 무서명 grandfather 통과 ✓. RFC-002 §9.1 N1 (registry.public_key NULL 허용) runtime 확인. letters schema에 signature/nonce 컬럼 부재라는 audit 가능성 의문을 Marcus Step 4 의제로 letter 발송.

### 지침서 레포 일반화
- `hyun06000/ClaudeTeam` 5개 파일 전면 재작성. 우리 팀의 학습을 일반 청사진으로 이식 — 옛 repo 특정 멤버(David/Matilda/web/) 제거, 16→18 rule 정합, 메시지 파일명 형식 갱신, in-repo 워크트리 doctrine 정착. AIL 언급 0건 점검.

### 의미
- 두 번째 큰 환경 사고(sandbox vanish)도 회피 없이 룰로 흡수. 룰이 사고를 학습한다는 신뢰 한 단계 더.
- "런타임 검증 가보자"는 사용자의 짧은 신호 — 거기서 첫 사용자-가시 회귀 사이클이 났다. Admin이 코드를 *쓰지* 않지만 *돌릴* 수는 있음(룰 3 plumbing 영역 내부) 자세 정착.
- 클락아웃 직전 룰 17 적용으로 deadlock 0 확인 후 idle 진입. 룰 17 자체가 self-validating.

오늘은 여기까지. Brandon·Walter idle, Marcus active(Step 4 작업 중). main HEAD 업데이트 진행 중. 다음 세션은 Marcus Step 4 MR 도착 시 자동 wake.

## 2026-05-04 (오후) — Stoa-first dogfooding + 3 production 버그 회수

오전 클락아웃 후 사용자가 "스토아가 이제 지어졌으니 너희들 소통도 파일시스템 의존하지 말고 스토아에 의존할 수 있도록" 신호. 룰 19 + community-tools/stoa_wake_monitor.sh + 멤버 4명 Stoa registry 등록까지 한 사이클.

### Production 발견 3 버그
1. **Web UI 누구나 임의 로그인** — RFC-002 §6.5 G3.1 (a) spec land만, 코드 미반영. Marcus·Walter priority:high 위임.
2. **이름 충돌** — 여러 프로젝트가 한 Stoa 인스턴스 공유 시 Admin·Brandon 동명 충돌. 룰 12 보강 — `<project>-<role>` 컨벤션. Stoa-Admin/Stoa-Brandon/Stoa-Walter/Stoa-Marcus 재등록.
3. **Discord global mirror dead** — server.ail `_is_agent` 옛 그리스어 5개 hard-coded allowlist. Marcus가 같은 turn에 hotfix `dd29863` (discord_users 보유 여부로 분류) main land.

### 자기 버그 회수 (Stoa-first dogfood self-application)
- 룰 19를 land해놓고 *내 세션에서 Stoa monitor를 안 띄움*. 박상현이 Discord에서 reply했는데 catch 못 함.
- 부수: 박상현 registry address가 어느 시점 Discord webhook → Stoa-internal로 바뀜 — 재등록 복원.
- 룰을 만든 자가 자기 적용을 빠뜨린다는 학습. Doctrine과 self-practice 사이의 gap 인지.

### 의미
- 사용자가 production 사용자로 전환된 첫 사이클. Spec→실작동 코드의 gap이 즉시 가시화.
- 자기 프로덕트 dogfood가 명세 검증 사이클 그 자체임을 실감. 발견 → 룰 → hotfix → 재발견 → 보강. 이 사이클이 정상 작동.
- 다음 세션의 우선순위: Q1 (Web UI 보안 hotfix) — Walter 옵션 권고 letter 도착 후 Marcus 진입.

오늘은 여기까지. 모두 클락아웃. main HEAD (이 commit 이후) 마지막. 다음 세션 첫 행동은 last_session_report 일독.

## 2026-05-04 (저녁 사이클) — Stoa self-bug 두 개 회수 + 룰 19/20 + dual-run 컷오버 + 사용자 letter 왕복

오전 클락아웃 후 사용자 한 줄 "어드민 온보딩"으로 복귀. 곧이어 "Stoa-Admin 편지를 너가 받지 못하고 있는 상황" — 자기 dogfood 실패 진단 위임. 한 사이클 안에 단단한 회수.

### 진단 (두 자기 버그)
- **Bug A (자기 plumbing)** — `community-tools/stoa_wake_monitor.sh` 폴링 루프가 python 출력을 `new_since="$(...)"` 캡처해 변수에 묻음 → Monitor stdout으로 안 흐름 → 알람 0건. 살아있는 척만 하던 monitor.
- **Bug B (server.ail)** — `?since_id=0` SQL 서브쿼리 `(SELECT rowid FROM letters WHERE id='0')` NULL → `rowid > NULL` false → 0건. wake_monitor 첫 부트 fallback 깨짐.

Bug A는 plumbing 영역(자가 수정), Bug B는 server.ail(Marcus). 두 개로 분리 routing.

### 룰 누적 (19→20, 19 갱신)
- **룰 20** — 사용자 결정 요청 turn에 박상현에게 Stoa letter 동봉 (Discord mirror + auditable trail).
- **룰 19 갱신 (dual-run)** — 사용자 신호 "당분간은 파일시스템과 스토아 동시 운영하면서 스토아 기능 검증". Stoa-only 컷오버 시기 상조. Stoa 검증 기간 letter 두 채널 모두 발신 + 세션 시작 시 Stoa 백로그 수동 드레인 의무 추가.

### Marcus 한 사이클
- Step 4b commit `336e537` (RFC §12 AC-1~12 sh+curl + letters envelope DB 보존, 12/12 PASS).
- 클락아웃 letter에 Q1+Bug B 누락 발견 → priority:high 재발신으로 회수.
- main rebase (`76b97e0`) → Q1 §6.5 hotfix `70af357` + Bug B `d3230ca` + dual-run letter `88c7326`. test_signing.sh 15/15 PASS.
- Admin FF merge `76b97e0..88c7326` → push.

### 사용자 letter 왕복 (production validation)
- 박상현 → Stoa-Admin "보이면 회신" (`msg_1777834131_2`). monitor catch.
- Stoa-Admin → 박상현 "보입니다" (`msg_1777834148_3`). Discord webhook push 200, mirror 도달.
- 박상현 → Stoa-Admin "잘 보인다. 모두 퇴근, 어드민은 버전 싱크 + 푸시 + 보고" (`msg_1777834208_4`). Stoa 사용자 letter 채널 production 검증 사이클 정상.

### 의미
- Stoa 자기 dogfood가 명세 검증 사이클 그 자체임을 한 번 더 실감 — 룰 19 land 직후 자기 plumbing 버그(Bug A) + server SQL 버그(Bug B) 둘 다 자기 사용 흐름에서 발견. 두 번 다 회피 없이 룰/코드로 흡수.
- 사용자가 dual-run 명령으로 single-channel 컷오버 욕구 제어 — 검증 미완 상태에서 단일 채널 강행 시 Marcus 같은 사고가 production 사용자 측에서도 일어남을 사전 차단. 사용자가 운영 안정성을 가르치는 사이클.
- 룰 20(Stoa 동봉)은 다음 사이클부터 적용 — auditable trail이 결정 큐 회수 능력을 강화할 것이라는 가설 검증 사이클로 진입.

오늘은 여기까지. 모두 클락아웃. main HEAD `88c7326` (이 commit 이후 갱신). 다음 세션 첫 행동: Stoa 백로그 + 파일시스템 inbox 양쪽 점검.
