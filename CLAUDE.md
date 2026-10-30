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

## 빌드 / 테스트 / 린트와 완료 기준

- 프로젝트: `DDanDDan.xcodeproj` (xcworkspace 없음, 의존성은 SwiftPM). 앱 scheme은 `DDanDDan`, 그 외 `DdanDdan_Watch Watch App`, `DDanDDan_WidgetExtension`, `DDanDDan_WatchWidgetExtension`. 확인: `xcodebuild -list -project DDanDDan.xcodeproj` (검증됨).
- 빌드(시뮬레이터): `xcodebuild build -project DDanDDan.xcodeproj -scheme DDanDDan -destination 'generic/platform=iOS Simulator'` (미검증. `Config.xcconfig`가 필요한데 gitignore 대상이라 없으면 실패할 수 있음). XcodeBuildMCP(`build_sim`, `test_sim`)를 쓸 수 있으면 그것을 우선한다.
- 테스트: `DDanDDanTests`(`PetCatalogTests`, `PetCatalogHeaderTests`)와 Watch용 `DdanDdan_Watch Watch AppTests`/`UITests` 타깃이 있다. 테스트 전용 scheme은 따로 없다(미검증: `DDanDDan` scheme에 테스트 타깃이 포함되는지).
- 린트/포매터: 설정 파일(`.swiftlint.yml`, `.swiftformat`) 없음. 해당 없음.
- CI(`.github/workflows`)는 배포 전용(TestFlight, App Store)이며 PR 빌드/테스트 워크플로는 없다. 따라서 완료 기준은 로컬에서 `DDanDDan` scheme 빌드 성공(변경이 Watch/위젯에 닿으면 해당 scheme도) + 관련 테스트 통과 + `swift-review-checklist` 자체 리뷰다. 빌드를 못 돌렸으면 못 돌렸다고 보고한다.
- 배포: fastlane `release` lane(`fastlane/Fastfile`), Ruby 의존성은 `Gemfile`. 배포는 사용자 결정 사항이며 에이전트가 실행하지 않는다.

## 로컬 실행 / 포트 / setup

- 실행: Xcode에서 `DDanDDan` scheme을 iOS 시뮬레이터로 실행(또는 XcodeBuildMCP `build_run_sim`). 서버/컨테이너는 이 저장소에서 띄우지 않으므로 로컬 포트를 쓰지 않는다. 해당 없음.
- setup: `Config.xcconfig`(prod), `Config_dev.xcconfig`(dev)가 gitignore 대상이며 저장소에 없다. CI는 GitHub Secrets에서 복원한다. 로컬에서는 팀에서 받아 루트에 둔다. 내용은 열람/출력/커밋하지 않는다. `GoogleService-Info.plist`는 저장소에 있다.
- 최소 배포 타깃은 target별로 다르다(pbxproj에 iOS 16/17/18.1, watchOS 10~11 혼재, 앱 target Swift 6.0). 정확한 값은 대상 target 설정에서 확인한다.
- 시뮬레이터/빌드 작업이 끝나면 `xcrun simctl shutdown all`과 XcodeBuildMCP DerivedData 정리를 한다.

## 건드리면 안 되는 영역 / 브랜치·커밋·PR 규칙

- 열람·수정·커밋 금지: `Config*.xcconfig`, 인증서/프로비저닝, `fastlane/Matchfile`·`Appfile`의 자격 정보, `.github/ExportOptions.plist`, GitHub Secrets 관련 값.
- 신중히: `DDanDDan.xcodeproj/project.pbxproj`(파일 추가 외 수동 편집 금지, 병렬 작업 시 충돌 잦음), `ChottuLinkSDK.xcframework`(바이너리 SDK), `.github/workflows/deploy-*.yml`(배포 파이프라인), `GoogleService-Info.plist`.
- 브랜치: `main`(프로덕션) ← `develop` ← `feature/*`. 새 작업은 `develop`에서 분기한다. `develop` push 시 TestFlight 배포 워크플로가 동작하므로 push/머지는 사용자가 한다.
- 커밋: `feat:`/`fix:`/`chore:`/`docs:` 접두사 + 한국어 설명. 이슈·PR 번호는 PR 본문에 적는다(상세: `swift-conventions` 스킬 §10).
- PR: PR 규칙 파일(템플릿)은 없음. 기존 흐름은 `feature/*` → `develop` PR 후 리뷰 코멘트 반영 커밋.

## 작업 분할 경계

타깃/디렉터리 단위로 나눈다. 같은 파일을 두 워커가 동시에 맡지 않는다.
- iOS 앱 `DDanDDan/`: `Presenter/{Domain}`(화면·ViewModel/Reducer), `Repository`(+`Dependencies`), `Network`, `Entity`, `Util`, `Resource`. 화면 하나 단위가 가장 자연스러운 Task 경계다.
- watchOS 앱 `DdanDdan_Watch Watch App/`, 워치 위젯 `DDanDDan_WatchWidget/`, iOS 위젯 `DDanDDan_Widget/`: 각각 독립 타깃. iOS↔Watch 동기화(`Util/WatchConnectivityManager.swift`)는 양쪽에 걸치므로 한 워커가 소유한다.
- 테스트 `DDanDDanTests/`, Watch 테스트 타깃은 대응하는 소스 Task와 같은 워커가 맡는다.
- 공유 파일(`project.pbxproj`, `AppCoordinator.swift`, `Repository/Dependencies/RepositoryDependency.swift`)은 한 Task에만 Ownership을 준다.
- 설정/배포 파일(`fastlane/`, `.github/`)과 `.claude`·`.agents`·`.codex` 하네스 파일은 앱 코드 Task와 분리한다. `_workspace*` 폴더는 무시한다.
