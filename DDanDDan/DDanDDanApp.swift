//
//  DDanDDanApp.swift
//  DDanDDan
//
//  Created by hwikang on 6/28/24.
//

import SwiftUI

import KakaoSDKCommon
import KakaoSDKAuth
import Firebase
import FirebaseMessaging
import FirebaseCrashlytics
import ChottuLinkSDK
import ComposableArchitecture

@main
struct DDanDDanApp: App {
    @StateObject var user = UserManager.shared
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    private let watchConnection = WatchConnectivityManager.shared
    
    init() {
        KakaoSDK.initSDK(appKey: Config.kakaoKey)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appCoordinator)
                .environmentObject(user)
                .environmentObject(deepLinkManager)
                .onOpenURL { url in
                    if (AuthApi.isKakaoTalkLoginUrl(url)) {
                       _ = AuthController.handleOpenUrl(url: url)
                    } else {
                        ChottuLink.handleLink(url)
                    }
                }
                .task {
                    _ = await RemoteConfigManager.shared.fetchAndActivate()
                }
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
    
    //TODO: 키값 추가 필요
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOption: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOption,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        
        let config = CLConfiguration(apiKey: Config.chottulinkKey, delegate: self)
        ChottuLink.initialize(config: config)
        
        return true
    }
    
    /// APNS 토큰과 등록 토큰 매핑
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let token = deviceToken.reduce("") {
            $0 + String(format: "%02X", $1)
        }
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error.localizedDescription)
    }
}


extension AppDelegate: MessagingDelegate{
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("---- receive fcmToken ----")
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        print(dataDict)
        UserDefaultValue.deviceToken = fcmToken
    }
}


@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
                                -> Void) {
        
        let userInfo = notification.request.content.userInfo
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        print(userInfo)
        
        completionHandler([[.banner, .badge, .sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Do Something With MSG Data...
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        print(userInfo)
        
        completionHandler()
    }
}

extension AppDelegate: ChottuLinkDelegate {
    func chottuLink(didResolveDeepLink link: URL, metadata: [String : Any]?) {
        if let metadata = metadata {
            print("📦 Metadata: \(metadata)")
            let originURL = metadata["originalURL"] as? String
            if let originURL = originURL {
                if let code = extractChottuInviteCode(from: originURL) {
                    DispatchQueue.main.async {
                        DeepLinkManager.shared.handleFriendInvite(code: code)
                    }
                }
            }
        }
    }
    
    func chottuLink(didFailToResolveDeepLink originalURL: URL?, error: any Error) {
        NSLog("Failed to resolve deep link: \(error.localizedDescription)")
    }
    
    func extractChottuInviteCode(from urlString: String,
                                 allowedHostSuffix: String = "chottu.link") -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let host = url.host,
              host.hasSuffix(allowedHostSuffix) else { return nil }
        
        var path = url.path
        while path.last == "/" { path.removeLast() }
        guard !path.isEmpty else { return nil }
        
        let rawCode = (path as NSString).lastPathComponent
        let code = rawCode.removingPercentEncoding ?? rawCode
        
        let pattern = #"^[A-Za-z0-9_-]{4,64}$"#
        if code.range(of: pattern, options: .regularExpression) == nil { return nil }
        
        return code
    }
    
}


struct ContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var user: UserManager
    @State private var mainTabStore = Store(initialState: MainTabReducer.State()) { MainTabReducer() }

    var body: some View {
        user.coordinator = coordinator
        return NavigationStack(path: $coordinator.navigationPath) {
            switch coordinator.rootView {
            case .splash:
                SplashView(viewModel: SplashViewModel(coordinator: coordinator, homeRepository: HomeRepository()))
            case .signUp:
                SignUpTermView(viewModel: SignUpViewModel(repository: SignUpRepository()), coordinator: coordinator)
            case .mainTab:
                MainTabView(coordinator: coordinator, store: mainTabStore)
            case .onboarding:
                OnboardingView(coordinator: coordinator)
            case .login:
                LoginView(viewModel: LoginViewModel(repository: LoginRepository(), appCoordinator: coordinator))
            }
        }
        .onChange(of: coordinator.rootView) { newValue in
            if newValue == .mainTab {
                mainTabStore = Store(initialState: MainTabReducer.State()) { MainTabReducer() }
            }
        }
    }
}

