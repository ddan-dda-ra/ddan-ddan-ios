//
//  RemoteConfigManager.swift
//  DDanDDan
//
//  Created by Assistant on 2024.
//

import Foundation
import FirebaseRemoteConfig


enum RemoteConfigKey: String {
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
    
    func getJsonValue(key: RemoteConfigKey) -> [String: Any]? {
        remoteConfig.configValue(forKey: key.rawValue).jsonValue as? [String: Any]
    }

}
