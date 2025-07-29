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
        
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            headers["App-Version"] = appVersion
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
       
        let dataTask = session.request(url, method: method, parameters: parameters, encoding: encoding, headers: networkHeaders)
            .validate(statusCode: 200..<401)
        
        // EmptyEntity인 경우 데이터 직렬화 스킵
        let result: AFDataResponse<Data>
        if T.self == EmptyEntity.self {
            result = await dataTask.serializingData(emptyResponseCodes: [200]).response
        } else {
            result = await dataTask.serializingData().response
        }
        
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
        
        guard let response = result.response else {
            print("🔹 Error: Invalid response")
            print("====================================")
            return .failure(NetworkError.invalidResponse)
        }
        
        print("🔹 Status Code: \(response.statusCode)")
        
        if response.statusCode == 400 {
            guard let data = result.data else {
                return .failure(NetworkError.dataNil)
            }
            
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
            // EmptyEntity 타입인 경우 데이터가 없어도 성공으로 처리
            if T.self == EmptyEntity.self {
                print("🔹 Success: Empty Response")
                print("====================================")
                guard let emptyValue = EmptyEntity.emptyValue() as? T else {
                    return .failure(.failToDecode("EmptyEntity 타입 캐스팅 실패"))
                }
                return .success(emptyValue)
            }
            
            guard let data = result.data, !data.isEmpty else {
                print("🔹 Error: Expected data but received empty response")
                print("====================================")
                return .failure(NetworkError.dataNil)
            }
            
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
