## 🏃‍♂️ 운동 다마고치, 딴딴 (DdanDdan)
> iOS & watchOS
<img width="2048" height="1000" alt="image" src="https://github.com/user-attachments/assets/c6c9f620-4941-427d-805f-29ade3c8e3e7" />

## 🛠️ 기술 스택 및 아키텍처

| 구분 | 기술 스택 |
|------|-----------|
| **Language** | Swift |
| **UI Framework** | SwiftUI |
| **Architecture** | TCA (The Composable Architecture) |
| **Asynchronous** | Swift Concurrency (Actor, async/await), Combine |
| **Apple Frameworks** | HealthKit, WCSession |
| **Networking** | Alamofire |
| **Authentication** | KakaoSDK |

## 🏗️ 아키텍처

### TCA (The Composable Architecture)
- **State 관리**: 앱의 모든 상태를 중앙에서 예측 가능하게 관리
- **Effect 처리**: Side Effect를 명확하게 분리하여 테스트 가능한 구조
- **Reducer**: 순수 함수를 통한 상태 변경 로직

### Coordinator Pattern
- **화면 이동 관리**: 각 화면 간의 네비게이션을 중앙에서 제어
- **의존성 분리**: View와 Navigation 로직의 완전한 분리
- **TCA 통합**: Coordinator와 TCA Store의 원활한 연동

```swift
App
├── Coordinator
│   ├── AppCoordinator
├── Features (TCA)
│   ├── Main
│   │   ├── MainFeature.swift
│   │   └── MainView.swift
│   └── Settings
│       ├── SettingsFeature.swift
│       └── SettingsView.swift
└── Shared
    ├── Models
    ├── Network
    └── Extensions
```
### 브랜치 전략
- `main`: 프로덕션 브랜치
- `develop`: 개발 브랜치  
- `feature/*`: 기능 개발 브랜치


---

**Built with ❤️ using TCA & SwiftUI**
