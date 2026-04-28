---
name: swift-review-checklist
description: ddan-ddan-ios의 Swift/SwiftUI 코드 자체 리뷰 체크리스트. swift-reviewer 에이전트가 PR 직전 또는 외부 PR 리뷰 코멘트 반영 전에 사용한다. 코드 변경 검토, 자체 리뷰, PR 리뷰 반영, "리뷰 한번 해줘" 요청 시 반드시 트리거.
---

# swift-review-checklist — ddan-ddan-ios

ddan-ddan-ios의 Swift/SwiftUI 코드를 자체 리뷰할 때 따라야 할 체크리스트. **swift-reviewer 에이전트가 항상 참조**한다. 본 프로젝트의 실제 PR 리뷰에서 반복 지적된 항목을 우선 정렬.

## 0. 심각도 정의

- **Blocker** — 크래시, 데이터 유실, 인증/보안 문제, 명확한 빌드 실패. → 반드시 수정.
- **Major** — 메모리 누수, 동시성 결함, 접근성 결함, watchOS 동기화 누락, 권한 추론 오류. → 수정 강력 권고.
- **Minor** — 컨벤션 위배, 명명, 가독성, 중복. → 제안.
- **Nit** — 취향. → 무시 가능.

## 1. 메모리 / 라이프사이클 [Major]

- [ ] `Task { ... }` 내 self 캡처 시 `[weak self]` (특히 ObservableObject ViewModel).
- [ ] `HKObserverQuery`, `WCSession` delegate, NotificationCenter observer는 해제 경로 존재.
- [ ] `@StateObject` (소유) vs `@ObservedObject` (외부) 적절히 구분 — 잘못 쓰면 화면 갱신마다 재생성/누수.
- [ ] 싱글톤(`HealthKitManager.shared` 등)에 누적 상태 있는지 — 로그아웃 시 정리되는지.

## 2. 동시성 [Major]

- [ ] HealthKit / WatchConnectivity / 네트워크 콜백 → UI 업데이트는 `@MainActor` 또는 `DispatchQueue.main`.
- [ ] `@Published` 변경은 메인 액터.
- [ ] actor 외부에서 actor-isolated 프로퍼티 접근 시 `await`.
- [ ] `@Sendable` 클로저에서 self 캡처 시 actor 격리 일관성.

## 3. HealthKit [Major] — 본 프로젝트 빈번 이슈

- [ ] 권한 상태를 `authorizationStatus(for:)` 단일 API로만 추론하지 않는다 (read 권한은 정확히 노출되지 않음).
- [ ] 실제 쿼리 결과 + status 조합으로 판단.
- [ ] ObserverQuery는 stop/cleanup 경로 있음.
- [ ] 권한 거부 시 UI 폴백(빈 상태, 안내 툴팁) 존재.
- [ ] `Info.plist` Usage Description 메시지 적절.
- 자세히: `swift-conventions/references/healthkit.md`.

## 4. WatchConnectivity [Major]

- [ ] 새 메시지 키가 iOS와 watchOS 양쪽에 모두 정의됨 (한쪽만이면 silent fail).
- [ ] foreground sendMessage 시 reachable 분기 + fallback.
- [ ] 큰 데이터는 `transferFile`/`transferUserInfo`.
- [ ] 백그라운드 콜백 UI 업데이트 메인 액터.
- 자세히: `swift-conventions/references/watch-connectivity.md`.

## 5. 딥링크 [Major]

- [ ] URL 파싱 시 `metadata["originalURL"]` 우선, `link` fallback.
- [ ] 단축 URL은 resolve 후 코드 추출.
- [ ] cold/warm start 두 경로 모두 처리.
- [ ] 로그인 전 진입 시 큐잉 (pendingDeepLink) → 로그인 후 소비.
- [ ] 처리 후 clear.
- [ ] iOS / Android 동시 빌드 영향 고려.
- 자세히: `swift-conventions/references/deeplink.md`.

## 6. SwiftUI 컨벤션 [Minor → Major]

- [ ] 색상은 Asset Catalog (`Color(.backgroundBlack)`), 하드코딩 hex 금지. **[Major]**
- [ ] `.adjusted`, `.adjustedWidth`, `.adjustedHeight` 일관 적용. **[Minor]**
- [ ] SE 디바이스 분기(`isSEDevice`) 누락 없음. **[Minor]**
- [ ] 공용 컴포넌트(`Components/`) 재사용 가능한지 먼저 검토. **[Minor]**
- [ ] 애니메이션의 `.animation(_:value:)` value 인자 누락 시 의도치 않은 재실행. **[Major]**
- [ ] `LazyVStack`/`LazyHStack`이 필요한 큰 리스트인데 `VStack`인지. **[Minor]**

## 7. 의존성 / 아키텍처 [Major]

- [ ] 새 Repository는 `RepositoryDependency.swift`에 등록되었나.
- [ ] TCA Reducer 변경 시 State equality 깨지지 않았나 (Equatable, Hashable).
- [ ] Coordinator path enum에 새 화면 등록되었나.
- [ ] 같은 도메인에서 ViewModel과 Reducer를 섞어 쓰지 않았나 (혼재는 OK이되 한 화면 안에서는 일관).

## 8. 네트워크 / 에러 [Major]

- [ ] 새 endpoint는 `*Network.swift`에 추가, `PathString` 사용.
- [ ] 토큰 인증 필요 endpoint가 `TokenInterceptor` 통과하는지.
- [ ] 에러 케이스(401/5xx) 처리 → 사용자 알림 또는 silent retry 결정.
- [ ] 네트워크 실패 시 로딩 인디케이터 해제.

## 9. Analytics [Minor]

- [ ] 신규 화면/액션에 GA 이벤트 누락 없음 (`AnalyticsManager` + `Util/Event/*`).
- [ ] 이벤트 키는 기존 컨벤션 따름.

## 10. 접근성 [Major] — 본 프로젝트 PR 리뷰에서 지적된 적 있음

- [ ] `Image`/`Button`에 `accessibilityLabel`.
- [ ] 동적 폰트(`.dynamicTypeSize`) 깨지지 않는 레이아웃.
- [ ] 색상 대비 (Asset에 다크/라이트 분리되어 있는지).
- [ ] 햅틱/소리만으로 정보 전달하는 곳 없는지.

## 11. 한국어 / 카피 [Minor]

- [ ] 사용자 가시 문구는 한국어, 코드 식별자는 영어.
- [ ] 띄어쓰기/맞춤법 (특히 dialog 본문).

## 12. 파일 헤더 / 정리 [Nit]

- [ ] 헤더 형식 일관 (`//  FileName.swift\n//  DDanDDan\n//  Created by ... on ....`).
- [ ] 미사용 import 제거.
- [ ] `//TODO:` 추가했다면 누가 언제 무엇을 할지 1줄 명시.
- [ ] `print(...)` 디버그 로그가 운영 빌드까지 가지 않는지 (혹은 OSLog).

## 13. 테스트 / 검증 [정보]

- 본 프로젝트는 자동 테스트가 거의 없음. 따라서 PR 본문에 **수동 검증 시나리오**를 적는 것이 사실상 표준.
- 빌드 검증은 사용자가 Xcode에서 직접. 리뷰어는 빌드를 시도하지 않음 (현재 CI 없음 — `.github/workflows`, GitLab CI, Jenkins 모두 미구성. CI 도입 시 이 줄을 갱신).

## 14. PR 리뷰 코멘트 반영 모드

외부 PR 코멘트를 받아 반영할 때:
1. 코멘트를 카테고리(블로커/제안/의문)로 분류.
2. 위 체크리스트 항목과 매핑.
3. 의문/거절 코멘트는 반영 전에 architect와 합의.
4. 반영 후 commit 메시지: `fix: PR 리뷰 반영 ({핵심 키워드})`.
