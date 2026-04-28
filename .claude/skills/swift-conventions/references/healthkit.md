# HealthKit 패턴 (ddan-ddan-ios)

이 프로젝트는 HealthKit으로 `activeEnergyBurned`(소모 칼로리)를 읽어 펫의 성장 로직과 연결한다. 사용자 권한 거부/부분 허용 케이스가 빈번하므로 권한 처리에 특별히 주의.

## 1. 진입점

`DDanDDan/Util/HealthKitManager.swift` (싱글톤). 모든 HealthKit 호출은 이 매니저를 통한다.

## 2. 권한 추론의 함정 (현재 구현 한계 포함)

- `HKHealthStore.authorizationStatus(for:)`는 **read 권한 상태를 정확히 알려주지 않는다.** Apple은 사용자 프라이버시 보호 차원에서 read 권한 상태를 노출하지 않음.
- 따라서 `isAuthorized()`만 믿고 분기하면 잘못 판단할 수 있다.
- **이상적인 패턴**: 실제 쿼리를 시도하고, 결과 데이터(0이거나 에러) + `authorizationStatus` 조합으로 판단.
- **현재 구현의 한계:** `HealthKitManager.readActiveEnergyBurned(completion:)` 는 다음 세 케이스 모두에서 동일하게 `0`을 반환하여 구분이 불가능하다:
  - `healthStore == nil` (HealthKit 미지원 디바이스)
  - 쿼리 에러 (권한 거부 포함)
  - 데이터가 정말 0kcal
  에러를 문자열 로그로만 처리하고 `HKError.notAuthorized` 같은 타입 검사를 하지 않음. 또 `HomeViewModel` 은 사실상 `isAuthorized()` 호출에만 의존.
- **권장 개선** (변경할 일이 있을 때): `readActiveEnergyBurned` 시그니처를 `Result<Double, HKError>` 또는 `async throws -> Double?` 로 바꾸고, "데이터 없음(0)"과 "권한 거부"·"디바이스 미지원"을 구분 가능하게. 그래야 권한 미허용 시 안내 툴팁(`feat: 건강 데이터 미허용 시 칼로리 영역에 안내 툴팁 추가`)이 false-positive 없이 노출된다.
- 최근 PR(`d545146 fix: PR 리뷰 반영 (권한 추론/ObserverQuery/접근성)`, `e20d630 docs: readActiveEnergyBurned 권한 추론 우선순위 docstring 정정`) 컨텍스트 참고.

## 3. ObserverQuery 라이프사이클

- `HKObserverQuery`는 long-running. `healthStore.execute(query)` 후 명시적으로 stop하지 않으면 계속 동작.
- **`HealthKitManager`는 싱글톤(`shared`)이므로 deinit이 사실상 일어나지 않는다 — deinit 기반 cleanup에 의존하지 말 것.**
- 화면이 사라질 때 `healthStore.stop(query)` 를 호출할 수 있는 **명시적 stop API** (예: `stopObserveActiveEnergyBurned()`) 를 매니저에 두고, `View`/`ViewModel` 의 lifecycle 훅(`.onDisappear` 또는 ViewModel deinit)에서 호출.
- 신규 ObserverQuery 추가 시 매니저에 stop API를 함께 추가하지 않으면 콜백·리소스가 백그라운드에서 영구 동작하여 배터리·발열·중복 알림의 원인이 된다.
- `enableBackgroundDelivery`는 백그라운드 갱신용. 권한 거부 또는 enable 실패 시 무조건 무시하지 말고, 최소한 OSLog로 기록하고 UX 정책을 정한다 (예: "권한 거부 시 안내 툴팁 노출").

## 4. 백그라운드 호출 → 메인스레드 UI

- ObserverQuery 콜백은 백그라운드 큐에서 호출됨.
- ViewModel의 `@Published` 업데이트는 반드시 메인 액터:
  ```swift
  await MainActor.run { self.kcal = kcal }
  // 또는 DispatchQueue.main.async { ... }
  ```

## 5. App Group 데이터 공유

- 위젯/Watch와 데이터 공유 위해 App Group `UserDefaults`에 칼로리 저장.
- 키 컨벤션 확인 후 추가 (기존 키와 충돌 금지).

## 6. 권한 미허용 시 UX

- 사용자 가시 안내가 필요한 경우 `TooltipView` 같은 컴포넌트 활용.
- 최근 도입된 패턴: `feat: 건강 데이터 미허용 시 칼로리 영역에 안내 툴팁 추가` (4174e72).

## 7. 체크리스트 (변경 시)

- [ ] `Info.plist`의 `NSHealthShareUsageDescription` 메시지 확인.
- [ ] 권한 추론을 단일 API에 의존하지 않는다.
- [ ] ObserverQuery는 stop 경로가 있다.
- [ ] 콜백 → UI 업데이트는 메인 액터.
- [ ] 권한 거부 케이스의 UI 분기 (빈 상태 / 안내 / 재요청).
- [ ] App Group 키 충돌 없음.
