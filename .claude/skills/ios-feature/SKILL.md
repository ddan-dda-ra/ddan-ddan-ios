---
name: ios-feature
description: ddan-ddan-ios의 iOS/SwiftUI 기능 추가, 버그 수정, 리팩터링, PR 리뷰 코멘트 반영 작업을 ios-architect → swift-implementer → swift-reviewer 3인 에이전트 팀으로 수행하는 오케스트레이터. ddan-ddan-ios 프로젝트의 어떤 코드 변경 요청(예 "Home에 X 버튼 추가해줘", "Setting의 Y 버그 수정", "PR 리뷰 반영해줘", "이 화면 다시 그려줘", "이 기능 보완해줘")에서도 반드시 사용. 단순 질문/탐색만 할 때는 사용 안 함.
---

# ios-feature — ddan-ddan-ios 기능/버그/리뷰 오케스트레이터

ddan-ddan-ios 프로젝트의 모든 코드 변경 작업을 3인 에이전트 팀이 협업하여 처리한다.

**팀 구성:**
- `ios-architect` — 변경 계획 (읽기만)
- `swift-implementer` — 실제 코드 작성/수정
- `swift-reviewer` — 자체 리뷰

**실행 모드:** 에이전트 팀 (`TeamCreate` + `TaskCreate` + `SendMessage`)

## Phase 0: 컨텍스트 확인

워크플로우 진입 시:

1. `_workspace/` 디렉토리 존재 여부 확인.
2. **존재 + 사용자가 같은 작업의 부분 수정 요청** ("리뷰어 의견 반영해서 다시", "X 부분만 다시"):
   → **부분 재실행 모드 (보수 조건부).**
   - 변경이 다음 "계약(contract)" 영역에 영향을 주지 않으면 해당 에이전트만 재호출, 기존 산출물 유지.
   - **계약 변경 시 architect도 함께 재실행 (최소 Phase 1 재평가):**
     - DI / `RepositoryDependency` 등록 추가·삭제·이름 변경
     - `AppCoordinator` 라우팅 / `*Path` enum / 화면 등록 / 딥링크 핸들링
     - HealthKit / WatchConnectivity 권한·세션 상태·동시성 계약
     - watchOS ↔ iOS 메시지 키·App Group 키
     - TCA Reducer State 형태 (Equatable 깨짐) / Reducer ↔ ViewModel 전환
     - 네트워크 endpoint contract (`PathString` 추가/변경)
   - 위 영역과 무관한 "텍스트 카피 수정", "스타일 미세조정", "이벤트명 오타", "주석/문서 보강" 등은 부분 재실행으로 안전.
3. **존재 + 사용자가 새 입력 제공** (다른 기능 요청):
   → 기존 `_workspace/`를 `_workspace_prev/`로 이동, 새 디렉토리 생성, **초기 실행**.
4. **미존재**: `_workspace/` 생성 후 **초기 실행**.

## Phase 1: 요구사항 분석 / 명료화

오케스트레이터(메인)가 수행. 팀 생성 전.

1. 사용자 요청을 한 줄로 요약.
2. 영향 범위가 명백히 큰 경우(전체 리팩터, 5개 화면 동시 변경 등) **사용자에게 분할 제안**.
3. 모호한 부분 1~2개를 짧게 질문 (이 단계에서 시간을 너무 쓰지 않는다).
4. 작업 유형 분류:
   - **a) 신규 기능 추가** — 전체 파이프라인.
   - **b) 버그 수정** — 전체 파이프라인 (architect는 원인 분석에 집중).
   - **c) PR 리뷰 코멘트 반영** — architect 생략 가능, reviewer가 코멘트를 분류 → implementer가 반영 → reviewer 재확인.
   - **d) 단순 리팩터** — 전체 파이프라인.

## Phase 2: 팀 구성 및 작업 할당

`TeamCreate` 로 팀 구성:
- 팀 이름: `ios-feature-team`
- 멤버: `ios-architect`, `swift-implementer`, `swift-reviewer`
- 모든 에이전트 호출 시 `model: "opus"` 명시.

`TaskCreate` 로 작업 등록 (의존성 포함):
1. **architect 작업** — "변경 계획 작성, 출력: `_workspace/01_architect_plan.md`"
2. **implementer 작업** — "계획대로 구현, 출력: `_workspace/02_implementer_changes.md`" (architect 작업에 blockedBy)
3. **reviewer 작업** — "변경 자체 리뷰, 출력: `_workspace/03_reviewer_findings.md`" (implementer 작업에 blockedBy)
4. **implementer 후속 작업** — "리뷰 반영" (reviewer 결과 Blocker/Major 있을 때만 등록)

**PR 리뷰 반영 모드(c)** 일 때:
1. reviewer가 먼저 코멘트 분류 (`_workspace/00_review_triage.md`).
2. implementer가 반영.
3. reviewer가 재확인.

## Phase 3: 자체 조율 모니터링

팀원들이 `SendMessage`/`TaskUpdate`로 자체 조율한다. 오케스트레이터는:

- 진행 상황을 가끔 `TaskList` 로 점검.
- 팀원 간 핑퐁(implementer ↔ reviewer 3회 이상)이면 architect 중재 요청.
- 사용자 추가 입력이 필요한 경우(권한, 디자인 결정) 즉시 사용자에게 질문.

## Phase 4: 결과 종합

모든 작업 완료 후:

1. `_workspace/03_reviewer_findings.md`의 종합 판정 확인.
2. 사용자에게 **2~3문장 요약** 보고:
   - 어떤 파일이 어떻게 바뀌었는지 (전체 목록 X, 핵심 1~3개)
   - 미해결 / 후속 작업 (있다면)
   - 사용자가 다음에 해야 할 것 (Xcode 빌드, 디바이스 테스트 등)
3. **commit/PR 메시지 안 1줄 제안** (한국어, 기존 컨벤션 따름).
4. `TeamDelete`로 팀 정리.

## Phase 5: 피드백 수집

사용자 응답 후:
- 명시적 추가 요청이 있으면 Phase 0부터 (부분 재실행 모드).
- 동일 유형 피드백이 반복되면 (2회+) 하네스 진화 제안 (CLAUDE.md 변경 이력에 기록 + 관련 스킬/에이전트 수정).

## 데이터 전달 프로토콜

- **태스크 기반**: 진행 상황과 의존성. `TaskCreate`/`TaskUpdate`.
- **파일 기반**: 산출물. `_workspace/` 하위.
  - `01_architect_plan.md`
  - `02_implementer_changes.md`
  - `03_reviewer_findings.md`
  - `00_review_triage.md` (PR 리뷰 모드 시)
- **메시지 기반**: 즉시 알림/질문. `SendMessage`.

## 에러 핸들링

- **architect가 요구사항 모호로 막힘** → 사용자에게 질문 1~2개 → 답 받으면 architect 재시작.
- **implementer가 컴파일 의심** → 일단 구현하고 02_implementer_changes.md "미완"에 명시. 사용자가 빌드 검증.
- **reviewer ↔ implementer 무한 루프** → architect 중재. 그래도 안 되면 사용자 결정.
- **에이전트 1회 재시도 후 재실패** → 해당 산출물 누락한 채 진행, 보고서에 명시.

## 테스트 시나리오

**정상 흐름 (신규 기능):**
사용자: "Setting에 알림 시간대 설정 화면 추가해줘"
1. Phase 1: 요구사항 명료화 — "특정 시간 푸시인지, 시간대 외 처리는?" 질문.
2. Phase 2: 팀 구성, 3개 작업 등록.
3. architect → 계획 (Setting 디렉토리에 새 View/ViewModel + Network endpoint).
4. implementer → 4개 파일 생성/수정 + RepositoryDependency 등록.
5. reviewer → minor 1개(접근성 라벨 추가 제안), Pass with minor.
6. implementer → minor 반영.
7. Phase 4: 사용자에게 요약 + 빌드 안내.

**에러 흐름 (요구사항 모호):**
사용자: "친구 화면 좀 개선해줘"
1. Phase 1: 너무 모호 → architect에게 넘기지 않고 사용자에게 "어떤 부분(목록 정렬/카드 디자인/검색)인지" 질문.
2. 사용자 답변 후 정상 흐름.

**PR 리뷰 반영 모드:**
사용자: "[GitHub PR URL의 코멘트들 붙여넣기] 반영해줘"
1. Phase 1: 작업 유형 (c)로 분류.
2. reviewer 먼저 코멘트 트리아지 → `00_review_triage.md`.
3. implementer 반영 → `02_implementer_changes.md`.
4. reviewer 재확인.
5. Phase 4: commit 메시지 안 (`fix: PR 리뷰 반영 (...)`) 제안.
