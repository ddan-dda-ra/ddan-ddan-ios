//
//  NetworkEvent.swift
//  DDanDDan
//
//  Created by keone on 2025/04/01.
//

import Foundation

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
