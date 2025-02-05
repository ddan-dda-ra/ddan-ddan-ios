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

@main
struct DDanDDanApp: App {
    @StateObject var user = UserManager.shared
    @StateObject private var appCoordinator = AppCoordinator()
    
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
                .onOpenURL { url in
                    if (AuthApi.isKakaoTalkLoginUrl(url)) {
                        AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
    
    //TODO: 키값 추가 필요
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        
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
        return true
    }
    
    /// APNS 토큰과 등록 토큰 매핑
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let token = deviceToken.reduce("") {
            $0 + String(format: "%02X", $1)
        }
        print(token)
        
        print("여기 출력 되나요?")
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
        // TODO: 서버 저장 필요 시 서버로 전송
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



struct ContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var user: UserManager
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            switch coordinator.rootView {
            case .splash:
                SplashView(viewModel: SplashViewModel(coordinator: coordinator, homeRepository: HomeRepository()))
            case .signUp:
                SignUpTermView(viewModel: SignUpViewModel(repository: SignUpRepository()), coordinator: coordinator)
            case .home:
                HomeView(coordinator: coordinator, viewModel: .init(repository: HomeRepository(), userInfo: coordinator.userInfo, petInfo: coordinator.petInfo))
            case .onboarding:
                OnboardingView(coordinator: coordinator)
            case .login:
                LoginView(viewModel: LoginViewModel(repository: LoginRepository(), appCoordinator: coordinator))
            }
        }
    }
}

