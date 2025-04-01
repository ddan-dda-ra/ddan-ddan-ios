//
//  AnalyticsManager.swift
//  DDanDDan
//
//  Created by keone on 2025/03/28.
//

import Foundation
import FirebaseAnalytics

class AnalyticsManager {
    public static let shared = AnalyticsManager()
    private init() {}
    
    public func logEvent(event: AnalyticsEvent) {
        Analytics.logEvent(event.title, parameters: event.parameter)
    }
    
    public func setUserProperty(property: UserProperty) {
        Analytics.setUserProperty(property.value, forName: property.name)
    }
}

protocol AnalyticsEvent {
    var title: String { get }
    var parameter: [String: Any] { get }
}

public enum UserProperty {
    case userID(String)
    case userName(String)
    
    var name: String {
        switch self {
        case .userID: return "user_id"
        case .userName: return "user_name"
        }
    }
    
    var value: String? {
        switch self {
        case .userID(let id): return id
        case .userName(let name): return name
        }
    }
}
