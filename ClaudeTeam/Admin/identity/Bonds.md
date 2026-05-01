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
