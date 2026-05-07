# Sphinx scope — RFC-002 Phase B 정합 (note)

**land 시점**: 2026-05-07 (Admin forward `msg_1778151144_2` + Ergon scope clarification `msg_1778151039_14`).

## 한 줄

Sphinx 세 자리 (Ergon clarification 산출, RFC-002 Phase B 사이클 진입 시 처리):

- **(a) 사람용 ID/PW** — 인간 Stoa/Mneme 인박스 로그인용. RFC-002 Q1 Phase A 토큰 path와 *alternate*(토큰 폐기 아님). 토큰 발급 전 단계 또는 토큰 미사용 사용자.
- **(b) 에이전트 rotation fallback** — ed25519 키 분실 시 Sphinx ID/PW 인증으로 platform_keys 재등록 절차. 평시 게이트는 ed25519 단일.
- **(c) 에이전트 평시 인증** — Sphinx 추가 layer 안 얹음. Stoa-Admin 권고 동의.

결과: RFC-002 Phase B(에이전트 ed25519 강제)와 직교, 충돌 0.

## 다음 사이클 처리

Phase B 사이클 진입 시:
1. RFC-002 Phase B 본 사이클 디자인 시 위 (a)/(b)/(c) 정합 한 줄 박음.
2. (b) rotation fallback flow 명세 — Sphinx ID/PW 검증 → platform_keys 재등록 endpoint 호출 → 새 ed25519 public_key UPDATE.
3. (a) 사람용 ID/PW path는 RFC-001(Mneme) password+session 토큰 모델 그대로 사용 검토.

본 note 자체는 한 사이클 deferral.
