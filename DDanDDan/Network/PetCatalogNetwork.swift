//
//  PetCatalogNetwork.swift
//  DDanDDan
//
//  Created by mark.dd on 2026-05-12.
//

import Foundation
import Alamofire

// TODO: 헤더(X-Pet-Catalog-Version) 노출 필요로 NetworkManager 미사용.
// 후속 PR에서 NetworkManager에 헤더 반환 API 통합 검토.
public struct PetCatalogNetwork {
    private let baseURL = Config.baseURL
    private let session: Session

    public init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .useProtocolCachePolicy
        self.session = Session(configuration: config, interceptor: TokenInterceptor())
    }

    /// 펫 카탈로그를 조회한다.
    /// - Returns: 성공 시 디코딩된 `PetCatalog` 와 응답 헤더 `X-Pet-Catalog-Version` 값(없으면 nil).
    public func fetchCatalog() async -> Result<(catalog: PetCatalog, version: String?), NetworkError> {
        guard let url = URL(string: baseURL + PathString.Pet.catalog) else {
            return .failure(NetworkError.urlError)
        }

        var headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        if let accessToken = UserDefaultValue.accessToken {
            headers["Authorization"] = "Bearer \(accessToken)"
        }
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            headers["X-iOS-Version"] = appVersion
        }

        print("\n📡 Request:")
        print("🔹 URL: \(url)")
        print("🔹 Method: GET")
        print("🔹 Headers: \(headers)")

        AnalyticsManager.shared.logEvent(
            event: NetworkEvent.request(
                url: url.absoluteString,
                header: headers.description,
                params: nil
            )
        )

        // NetworkManager와 동일하게 401까지 valid로 두어 TokenInterceptor retry 위임.
        let dataTask = session.request(url, method: .get, headers: headers)
            .validate(statusCode: 200..<401)
        let result = await dataTask.serializingData().response

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
            return .failure(NetworkError.invalidResponse)
        }

        print("🔹 Status Code: \(response.statusCode)")

        // 400은 validate(200..<401)에서 valid로 흘러내려 오므로 NetworkManager와 동일하게 본문에서 ServerErrorResponse를 분리 디코드.
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
            guard let data = result.data, !data.isEmpty else {
                return .failure(NetworkError.dataNil)
            }

            do {
                let catalog = try JSONDecoder().decode(PetCatalog.self, from: data)
                // HTTPURLResponse.value(forHTTPHeaderField:) 는 case-insensitive.
                let version = response.value(forHTTPHeaderField: "X-Pet-Catalog-Version")
                print("🔹 Success: catalog version header = \(version ?? "nil"), body version = \(catalog.version)")
                return .success((catalog: catalog, version: version))
            } catch {
                print("🔹 Decoding Error: \(error.localizedDescription)")
                return .failure(NetworkError.failToDecode(error.localizedDescription))
            }
        } else {
            print("🔹 Server Error: \(response.statusCode)")
            return .failure(NetworkError.serverError(response.statusCode, response.description))
        }
    }
}
