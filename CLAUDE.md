# ddan-ddan-ios

운동 다마고치 앱 (iOS + watchOS). SwiftUI, TCA + Coordinator + MVVM 혼재, HealthKit 연동, KakaoSDK 인증, ChottuLink 딥링크.

## 하네스: ddan-ddan-ios feature/bug/review

**목표:** SwiftUI/iOS 코드 변경 작업을 architect → implementer → reviewer 3인 에이전트 팀으로 수행하여 일관된 컨벤션과 자체 리뷰 품질을 확보한다.

**트리거:** ddan-ddan-ios의 코드 변경(기능 추가, 버그 수정, 리팩터, PR 리뷰 코멘트 반영) 요청 시 `ios-feature` 스킬을 사용하라. 단순 질문/탐색/설명만 요청 시에는 직접 응답한다.

**브랜치 전략:** `main` (프로덕션) ← `develop` (개발) ← `feature/*`. 새 작업은 develop에서 분기.

**변경 이력:**
| 날짜 | 변경 내용 | 대상 | 사유 |
|------|----------|------|------|
| 2026-04-28 | 초기 구성 (3인 팀 + 2개 도메인 스킬 + 1개 오케스트레이터) | 전체 | - |
| 2026-04-28 | PR #64 리뷰 반영 (CodeRabbit 7건) | implementer/reviewer 가드레일, ios-feature 부분 재실행 보수 조건, deeplink·healthkit references 실제 구현 정합 | 가드레일 강화 + 문서-코드 정합성 보강 |
