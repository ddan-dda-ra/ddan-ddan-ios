# HealthKit 패턴 (ddan-ddan-ios)

이 프로젝트는 HealthKit으로 `activeEnergyBurned`(소모 칼로리)를 읽어 펫의 성장 로직과 연결한다. 사용자 권한 거부/부분 허용 케이스가 빈번하므로 권한 처리에 특별히 주의.

## 1. 진입점

`DDanDDan/Util/HealthKitManager.swift` (싱글톤). 모든 HealthKit 호출은 이 매니저를 통한다.

## 2. 권한 추론의 함정

- `HKHealthStore.authorizationStatus(for:)`는 **read 권한 상태를 정확히 알려주지 않는다.** Apple은 사용자 프라이버시 보호 차원에서 read 권한 상태를 노출하지 않음.
- 따라서 `isAuthorized()`만 믿고 분기하면 잘못 판단할 수 있다.
- **권장 패턴**: 실제 쿼리를 시도하고, 결과 데이터(0이거나 에러) + `authorizationStatus` 조합으로 판단.
- 최근 PR(`d545146 fix: PR 리뷰 반영 (권한 추론/ObserverQuery/접근성)`, `e20d630 docs: readActiveEnergyBurned 권한 추론 우선순위 docstring 정정`) 컨텍스트 참고.

## 3. ObserverQuery 라이프사이클

- `HKObserverQuery`는 long-running. `healthStore.execute(query)` 후 명시적으로 stop하지 않으면 계속 동작.
- 화면이 사라질 때 `stop(query)` 또는 매니저 deinit에서 정리.
- `enableBackgroundDelivery`는 백그라운드 갱신용. 권한 거부 시 실패 무시 처리.

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
