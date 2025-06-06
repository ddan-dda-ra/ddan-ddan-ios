//
//  NetworkManager.swift
//  DDanDDan
//
//  Created by hwikang on 10/23/24.
//

import Foundation
import Alamofire

public struct NetworkManager {
    private let baseURL = Config.baseURL
    private let session: Session
    
    public init(withInterceptor:Bool = true) {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = Session(configuration: config, interceptor: withInterceptor ? TokenInterceptor() : nil)
        
    }
    
    private func createHeaders(excludeAuth: Bool = false, additionalHeaders: HTTPHeaders? = nil) -> HTTPHeaders {
        var headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        if !excludeAuth, let accessToken = UserDefaultValue.accessToken {
            headers["Authorization"] = "Bearer \(accessToken)"
        }
        
        if let additionalHeaders = additionalHeaders {
            for header in additionalHeaders {
                headers[header.name] = header.value
            }
        }
        
        return headers
    }

    
    public func request<T: Decodable>(
        url: String,
        method: HTTPMethod,
        headers: HTTPHeaders? = nil,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        excludeAuth: Bool = false
    ) async -> Result<T, NetworkError> {
        guard let url = URL(string: baseURL + url) else {
            return .failure(NetworkError.urlError)
        }
        let networkHeaders = createHeaders(excludeAuth: excludeAuth, additionalHeaders: headers)
        
        print("\n📡 Request:")
        print("🔹 URL: \(url)")
        print("🔹 Method: \(method.rawValue)")
        print("🔹 Headers: \(networkHeaders)")
        
        if let parameters = parameters {
            print("🔹 Parameters: \(parameters)")
        }
        
        AnalyticsManager.shared.logEvent(event: NetworkEvent.request(url: url.absoluteString, header: networkHeaders.description, params: parameters?.description))
       
        let result = await session.request(url, method: method, parameters: parameters, encoding: encoding, headers: networkHeaders)
            .validate(statusCode: 200..<401)
            .serializingData()
            .response
        
        // 응답 로그 출력
        print("\n📥 Response:")
        if let error = result.error {
            print("🔹 AFError: \(error.localizedDescription)")
            
            if let statusCode = error.responseCode {
                if let data = result.data {
                    do {
                        let errorResponse = try JSONDecoder().decode(ServerErrorResponse.self, from: data)
                        print("🔹 Server Error Code: \(errorResponse.code)")
                        print("🔹 Server Error Message: \(errorResponse.message)")
                        AnalyticsManager.shared.logEvent(event: NetworkEvent.onError(errorResponse))
                        return .failure(NetworkError.serverError(statusCode, errorResponse.code))
                    } catch {
                        return .failure(NetworkError.failToDecode(error.localizedDescription))
                    }
                } else {
                    print("🔹 Server Error: No data available")
                    return .failure(NetworkError.serverError(statusCode, "Unknown error"))
                }
            }
            
            return .failure(NetworkError.requestFailed(error.errorDescription ?? "Unknown error"))
        }
        
        guard let data = result.data else {
            print("🔹 Error: Data is nil")
            print("====================================")
            return .failure(NetworkError.dataNil)
        }
        
        guard let response = result.response else {
            print("🔹 Error: Invalid response")
            print("====================================")
            return .failure(NetworkError.invalidResponse)
        }
        
        print("🔹 Status Code: \(response.statusCode)")
        
        if response.statusCode == 400 {
            do {
                let errorResponse = try JSONDecoder().decode(ServerErrorResponse.self, from: data)
                print("🔹 400 Error - Code: \(errorResponse.code), Message: \(errorResponse.message)")
                AnalyticsManager.shared.logEvent(event: NetworkEvent.onError(errorResponse))
                return .failure(NetworkError.serverError(400, errorResponse.code))
            } catch {
                print("🔹 400 Decoding Error: \(error.localizedDescription)")
                return .failure(NetworkError.failToDecode(error.localizedDescription))
            }
        }
        
        if 200..<300 ~= response.statusCode {
            do {
                let networkResponse = try JSONDecoder().decode(T.self, from: data)
                print("🔹 Success: \(networkResponse)")
                print("====================================")
                return .success(networkResponse)
            } catch {
                print("🔹 Decoding Error: \(error.localizedDescription)")
                print("====================================")
                return .failure(NetworkError.failToDecode(error.localizedDescription))
            }
        } else {
            print("🔹 Server Error: \(response.statusCode)")
            print("====================================")
            return .failure(NetworkError.serverError(response.statusCode, response.description))
        }
    }
}
