# 딥링크 패턴 (ddan-ddan-ios)

친구 초대를 ChottuLinkSDK 동적링크로 처리. iOS↔Android 호환성과 cold/warm start 처리에 주의.

## 1. 진입점

- `DDanDDan/DeepLinkManager.swift` — `DeepLinkType` enum + `pendingDeepLink` Combine Publisher.
- `InviteLinkBuilder` — ChottuLink 동적 링크 생성.
- App에서 URL 수신 → `DeepLinkManager.handleFriendInvite(code:)` 호출 → `pendingDeepLink` 발행.

## 2. URL 파싱 — `metadata["originalURL"]` 우선 + `code` 쿼리 파라미터 추출

- 최근 fix(`ebee7e9 fix: metadata["originalURL"]을 우선 사용하고 link를 fallback으로 변경`).
- ChottuLink resolve 결과에서 metadata와 link 두 곳에 URL이 있을 수 있음. **metadata.originalURL을 우선**, 없으면 link로 fallback.
- `f648601 fix: 딥링크 친구 초대 코드 추출 시 resolve된 URL 사용` — 단축 URL을 resolve한 뒤, **`code` 쿼리 파라미터에서 친구 코드를 추출**한다.
- 추출 규칙: `URLComponents(url:resolvingAgainstBaseURL: false).queryItems?.first(where: { $0.name == "code" })?.value`.
- 링크 생성 측 (`InviteLinkBuilder.makeInviteURL`)이 `URLQueryItem(name: "code", value: trimmed)` 으로 만들기 때문에 추출도 동일 키를 사용해야 함. 키가 바뀌면 양쪽 동시 변경.

## 3. iOS↔Android 호환

- `36bd60b fix: iOS↔Android 친구추가 딥링크 호환성 수정` 맥락 참고.
- `setIOSBehaviour(.app)`, `setAndroidBehaviour(.app)` 양쪽 설정.
- 도메인: `ddanddan.chottu.link`.

## 4. Cold start / Warm start (현재 구현 기준)

- App이 종료된 상태에서 딥링크로 진입(cold start)할 때 vs 백그라운드에서 복귀(warm start).
- **현재 동작:** `DeepLinkManager.handleFriendInvite(code:)` 가 두 가지를 동시에 수행한다.
  1. `@Published var pendingDeepLink` 에 **마지막 값을 덮어씀** (큐잉 아님 — 두 개 이상의 딥링크가 짧은 시간에 들어오면 마지막 것만 남음).
  2. `NotificationCenter.default.post(name: .friendInviteDeepLink, object: code)` 로 알림 발행 — **실제 소비 경로는 NotificationCenter 측이 메인**.
- **알려진 한계 (코드 변경 시 함께 검토):**
  - `pendingDeepLink` 는 `@Published` 메모리 전용. **앱 강제 종료 후 재기동 시 유실**. 영속화가 필요하면 UserDefaults 등으로 보강.
  - `clearPendingDeepLink()` 메소드가 정의되어 있지만 **현재 코드 어디에서도 호출되지 않음**. 만약 `pendingDeepLink` 기반 흐름을 활용하려면 로그인 성공/실패 시점 등에서 명시적으로 호출해야 함.
- **변경 제안 시 결정:** (A) 기존 NotificationCenter 흐름을 유지하고 `pendingDeepLink` 를 제거, 또는 (B) `pendingDeepLink` 를 진짜 큐로 만들고 cold-start 영속화 + clear 호출 경로 도입. 한쪽으로 정리하지 않으면 두 메커니즘이 공존하여 디버깅 난도가 올라간다.

## 5. Universal Link

- Apple App Site Association(AASA) 등록.
- `Info.plist`의 Associated Domains 확인.
- Universal link 도착 시 `application(_:continue:restorationHandler:)` 경로 → DeepLinkManager로 위임.

## 6. 체크리스트 (변경 시)

- [ ] URL 파싱 — metadata.originalURL 우선, link fallback.
- [ ] cold/warm start 양 경로 검증.
- [ ] iOS와 Android 양쪽 동작 확인 (베타 빌드).
- [ ] 처리 후 `pendingDeepLink` 정리.
- [ ] 로그인 전/후 진입 모두 시뮬.
- [ ] 잘못된 코드/만료 링크의 에러 UX.
