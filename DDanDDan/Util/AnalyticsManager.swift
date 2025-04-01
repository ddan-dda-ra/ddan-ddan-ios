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
}

protocol AnalyticsEvent {
    var title: String { get }
    var parameter: [String: Any] { get }
}

enum NetworkEvent: AnalyticsEvent {
    case onError(ServerErrorResponse)
    
    var title: String {
        switch self {
        case .onError: "network_error"
        }
    }
    
    var parameter: [String : Any] {
        switch self {
        case let .onError(response):
            return ["messege": response.message, "code": response.code]
        }
    }
    
    
}
