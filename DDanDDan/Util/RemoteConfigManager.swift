//
//  RemoteConfigManager.swift
//  DDanDDan
//
//  Created by Assistant on 2024.
//

import Foundation
import FirebaseRemoteConfig
//import FirebaseRemoteConfigSwift

private enum RemoteConfigKey: String {
    case forceUpdate = "force_update"
}


class RemoteConfigManager {
    static let shared = RemoteConfigManager()
    
    private let remoteConfig: RemoteConfig
    
    private init() {
        remoteConfig = RemoteConfig.remoteConfig()
        
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
    }
    
    func fetchAndActivate() async -> Bool {
        do {
            try await remoteConfig.fetchAndActivate()
            return true
        } catch {
            print("RemoteConfig fetch failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func checkForceUpdate() -> Bool {
        
        guard let forceUpdateConfig = remoteConfig.configValue(forKey: RemoteConfigKey.forceUpdate.rawValue).jsonValue as? [String: Any],
        let minAppVersionIOS = forceUpdateConfig["min_app_version_ios"] as? String,
        let forceUpdateEnabled = forceUpdateConfig["force_update_enabled"] as? Bool else {
            return false
        }
        
        return forceUpdateEnabled && isVersionLower(minimum: minAppVersionIOS)
    }
    
    private func isVersionLower(minimum: String) -> Bool {
        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

        return current.compare(minimum, options: .numeric) == .orderedAscending
    }
    
    func getAppStoreURL() -> URL? {
        return URL(string: "https://apps.apple.com/app/id6736588896")
    }
}
