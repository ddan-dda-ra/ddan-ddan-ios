//
//  NetworkEvent.swift
//  DDanDDan
//
//  Created by keone on 2025/04/01.
//

import Foundation

enum NetworkEvent: AnalyticsEvent {
    case request(url: String, header: String?, params: String?)
    case onError(ServerErrorResponse)
    
    var title: String {
        switch self {
        case .request: "network_request"
        case .onError: "network_error"
        }
    }
    
    var parameter: [String : Any] {
        switch self {
        case let .request(url, header, params):
            let header = if let header { header } else { "" }
            let params = if let params { params } else { "" }
            return ["url": url, "header": header, "params": params]
        case let .onError(response):
            return ["messege": response.message, "code": response.code]
        }
    }
    
    
}
