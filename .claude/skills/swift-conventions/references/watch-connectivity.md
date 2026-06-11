# WatchConnectivity 패턴 (ddan-ddan-ios)

iOS 앱과 watchOS 앱 간 데이터 동기화. `WatchConnectivityManager` (싱글톤) 통해서만 사용한다.

## 1. 진입점

- `DDanDDan/Util/WatchConnectivityManager.swift` (iOS 측)
- watchOS 측 대응 매니저는 `DdanDdan_Watch Watch App/` 하위.

## 2. 메시지 종류

| 함수 | 용도 | 보장 |
|------|------|------|
| `sendMessage(_:replyHandler:errorHandler:)` | 즉시 전송 (foreground) | reachable일 때만 |
| `transferUserInfo(_:)` | 비동기, 보장 전달 (백그라운드 OK) | 활성화 후 모두 도달 |
| `updateApplicationContext(_:)` | 마지막 상태 1개만 | 효율적 상태 동기화 |
| `transferFile(_:)` | 파일 전송 | 큰 데이터 |

**선택 기준:**
- 실시간 단발 → `sendMessage`
- 활동 데이터/이벤트 → `transferUserInfo`
- "현재 상태"만 중요한 경우 → `updateApplicationContext`

## 3. 메시지 키 컨벤션

- 키 문자열을 enum/상수로 정의하여 iOS↔watchOS 양쪽에서 공유.
- 새 키 추가 시 양쪽 모두 업데이트 (한쪽만 하면 무시되어 silent fail).

## 4. 세션 활성화

- 앱 시작 시 `WCSession.default.activate()` (init에서).
- `sessionDidDeactivate`에서 다시 `activate()` 호출 (iOS 측 다중 watch 지원).

## 5. 메인 액터 / 동시성

- `didReceiveMessage`는 background queue에서 호출됨.
- `@Published` 업데이트 또는 UI 변경은 반드시 메인 액터.

## 6. 디버깅

- `print(...)` 디버그 로그가 다수 존재 → 운영 코드에서는 OSLog로 점진 교체 권장.
- watch와 통신 안되면: 시뮬레이터는 페어링 환경 다름 → 실기기 검증 필요.

## 7. 체크리스트 (변경 시)

- [ ] 새 메시지 키를 iOS와 watchOS 양쪽에 추가.
- [ ] reachable 분기 (foreground sendMessage 시) — fallback으로 transferUserInfo 고려.
- [ ] 백그라운드 콜백 → UI 업데이트는 메인 액터.
- [ ] 큰 데이터(이미지 등)는 `transferFile` 사용.
- [ ] 앱 종료 후 데이터 보존이 필요하면 App Group UserDefaults도 함께 갱신.
