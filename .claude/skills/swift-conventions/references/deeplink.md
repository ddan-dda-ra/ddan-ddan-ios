# 딥링크 패턴 (ddan-ddan-ios)

친구 초대를 ChottuLinkSDK 동적링크로 처리. iOS↔Android 호환성과 cold/warm start 처리에 주의.

## 1. 진입점

- `DDanDDan/DeepLinkManager.swift` — `DeepLinkType` enum + `pendingDeepLink` Combine Publisher.
- `InviteLinkBuilder` — ChottuLink 동적 링크 생성.
- App에서 URL 수신 → `DeepLinkManager.handleFriendInvite(code:)` 호출 → `pendingDeepLink` 발행.

## 2. URL 파싱 — `metadata["originalURL"]` 우선

- 최근 fix(`ebee7e9 fix: metadata["originalURL"]을 우선 사용하고 link를 fallback으로 변경`).
- ChottuLink resolve 결과에서 metadata와 link 두 곳에 URL이 있을 수 있음. **metadata.originalURL을 우선**, 없으면 link로 fallback.
- `f648601 fix: 딥링크 친구 초대 코드 추출 시 resolve된 URL 사용` — 단축 URL을 resolve한 뒤 코드를 추출해야 함.

## 3. iOS↔Android 호환

- `36bd60b fix: iOS↔Android 친구추가 딥링크 호환성 수정` 맥락 참고.
- `setIOSBehaviour(.app)`, `setAndroidBehaviour(.app)` 양쪽 설정.
- 도메인: `ddanddan.chottu.link`.

## 4. Cold start / Warm start

- App이 종료된 상태에서 딥링크로 진입(cold start)할 때 vs 백그라운드에서 복귀(warm start).
- `pendingDeepLink`로 큐잉 후, 적절한 시점에 소비 (로그인 완료 후 등).
- 사용 후 `clearPendingDeepLink()` 호출 (재진입 시 중복 처리 방지).

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
