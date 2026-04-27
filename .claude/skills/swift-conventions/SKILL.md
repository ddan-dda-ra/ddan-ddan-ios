---
name: swift-conventions
description: ddan-ddan-ios 프로젝트의 Swift/SwiftUI 코드 컨벤션, 디렉토리 구조, 의존성 주입(Dependencies), 화면 사이즈 어댑터(.adjusted), Asset 색상 참조, 한국어 커밋 메시지 규칙을 담는 가이드. ddan-ddan-ios 프로젝트의 어떤 Swift 파일을 추가/수정/리뷰하든 항상 이 스킬을 참조할 것. TCA Reducer, Coordinator, ViewModel, Repository, Network, HealthKit, WatchConnectivity 작업 시 반드시 트리거.
---

# swift-conventions — ddan-ddan-ios

ddan-ddan-ios 프로젝트의 Swift 코드 작성 시 따라야 할 컨벤션. **계획·구현·리뷰의 모든 에이전트가 참조**한다.

## 1. 디렉토리 구조

```
DDanDDan/
├── DDanDDanApp.swift               # @main, app entry
├── AppCoordinator.swift            # navigation root
├── DeepLinkManager.swift           # URL/Universal Link 처리
├── Entity/                         # 도메인별 모델 (Auth/Cheer/Friend/Home/Pet/Rank/User/Error)
├── Network/                        # Alamofire 기반 *Network.swift + 인터셉터
├── Repository/                     # 도메인별 Repository (DI 진입점)
│   └── Dependencies/RepositoryDependency.swift  # DependencyValues extension
├── Presenter/                      # 화면 + ViewModel (또는 TCA Reducer)
│   ├── Components/                 # 공용 SwiftUI 컴포넌트
│   ├── Home / Friends / Login / Main / Onboarding / Rank / Setting / Splash
└── Util/                           # AnalyticsManager, HealthKitManager,
                                    # WatchConnectivityManager, RealtimeDBManager,
                                    # RemoteConfigManager, UserDefaultValue, Extension/, Event/
```

**규칙:**
- 새 화면은 `Presenter/{Domain}/` 하위에 배치.
- 공용 UI 컴포넌트(다른 화면에서도 재사용 가능)는 `Presenter/Components/`.
- Repository는 1도메인 1파일(`{Domain}Repository.swift`).
- Watch 앱 코드는 `DdanDdan_Watch Watch App/` 별도 타겟.

## 2. 아키텍처 — TCA + MVVM 혼재

**현실:** 일부는 TCA(`Reducer` + `Store`), 일부는 MVVM(`ViewModel`). 혼재된 상태이고, 함부로 한쪽으로 통일하지 않는다.

**판단 규칙:**
- 같은 디렉토리의 인접 파일을 본다. `HomeView`가 `HomeViewModel`을 쓰면 같은 도메인의 새 화면도 ViewModel 패턴.
- 리스트/랭킹/친구 등 신규로 도입되는 부분에 TCA가 더 많이 쓰임 (e.g. `RankViewReducer`).
- 새 화면을 추가할 때 패턴 선택이 모호하면 architect가 판단.

**Coordinator:** `AppCoordinator`가 모든 navigation을 관리. 새 화면 push 시 `enum {Domain}Path: Hashable`을 정의하고 navigation destination 등록.

## 3. 의존성 주입 — `Dependencies` 패키지

```swift
import Dependencies

extension DependencyValues {
    var fooRepository: FooRepository {
        get { self[FooRepository.self] }
        set { self[FooRepository.self] = newValue }
    }
}
```

신규 Repository 추가 시 **반드시** `RepositoryDependency.swift`에 등록. 사용처에서는 `@Dependency(\.fooRepository)`.

## 4. SwiftUI 화면 컨벤션

**SE 디바이스 적응:**
```swift
private let isSEDevice = UIScreen.isSESizeDevice
// padding(.horizontal, isSEDevice ? 28 : 32.adjustedWidth)
// padding(.top, isSEDevice ? 16 : 54.adjustedHeight)
```

**`.adjusted`, `.adjustedWidth`, `.adjustedHeight`** — `Util/Extension/Adjusted+.swift` 정의. 디자인 기준 화면(보통 iPhone 13/14)의 값을 실제 디바이스에 비례 조정. 새 레이아웃 값에 일관되게 적용.

**색상:** `Color(.backgroundBlack)` 같이 Asset Catalog 참조. 하드코딩 hex 금지.

**컴포넌트 우선:** `Presenter/Components/`의 `DialogView`, `ToastView`, `TooltipView`, `GreenButton`, `HomeButton`, `NavigationBarView` 등 먼저 검토 후 재사용. 새로 만들기 전에 grep.

**Lottie:** `import Lottie` — 게임/펫 애니메이션에 활용.

**오버레이/토스트:** `TransparentOverlayView` + `ToastView` 조합 사용 (HomeView 참고).

## 5. 동시성 / 메모리

- `@StateObject` (소유) vs `@ObservedObject` (외부 주입) 구분.
- `Task { }` 내부에서 self 캡처 시 명시적 `[weak self]` (특히 `ViewModel`이 `ObservableObject`인 경우).
- HealthKit / WatchConnectivity 콜백은 보통 백그라운드 큐 → UI 업데이트는 `MainActor`/`DispatchQueue.main`.
- `@Sendable` 클로저 안 self 캡처 시 actor 격리 주의.
- `ObserverQuery` 등 long-running query는 deinit에서 해제(혹은 명시적 stop).

## 6. 네트워크 / 에러

- Alamofire 기반 `*Network.swift`. `NetworkManager`가 공통.
- `TokenInterceptor` + `TokenRefreshManager`로 자동 갱신.
- 에러 모델: `Entity/Error/ServerErrorResponse`.
- 네트워크 이벤트는 `Util/Event/NetworkEvent`로 Analytics 기록.

## 7. 분석 / 외부 SDK

- `AnalyticsManager` (Firebase GA) — 화면 진입/주요 이벤트 기록.
- `RealtimeDBManager`, `RemoteConfigManager` (Firebase) — 강제 업데이트 등.
- `KakaoSDK` — 로그인.
- `ChottuLinkSDK` — 친구 초대 딥링크.

## 8. 파일 헤더

기존 파일과 동일 형식:
```swift
//
//  FileName.swift
//  DDanDDan
//
//  Created by {git config user.name} on {YYYY-MM-DD or M/D/YY}.
//
```

날짜 형식은 인접 파일과 맞춘다 (`9/26/24` 또는 `2025/04/01` 둘 다 존재).

## 9. 한국어 / 영어

- **사용자 가시 문구**: 한국어 ("문의하기", "친구 초대", "건강 데이터 권한이 필요해요").
- **코드 식별자**: 영어 (`HomeViewModel`, `friendCardRepository`).
- **주석/docstring**: 한국어 OK. 최근 PR 리뷰 반영 커밋들은 한국어 docstring을 사용.

## 10. 커밋 메시지

`git log`에서 보이는 패턴:
- `feat: {한국어 또는 영어}` — 신규
- `fix: {간단 설명}` — 수정
- `chore: {한국어}` — 잡일 (버전 업, 이벤트 추가)
- `docs: {한국어}` — 문서/주석
- 본문은 보통 한국어. 이슈/PR 번호 직접 표기보다 PR 본문에 의존.

## 11. 도메인별 추가 가이드

세부 패턴은 references/에 분리:
- `references/healthkit.md` — HealthKit 권한·쿼리·ObserverQuery 패턴 (HealthKit 변경 시 반드시 읽기)
- `references/watch-connectivity.md` — iOS↔watchOS WCSession 메시징 (Watch 동기화 변경 시 반드시 읽기)
- `references/deeplink.md` — DeepLinkManager / Universal Link / ChottuLink (딥링크 작업 시 반드시 읽기)
