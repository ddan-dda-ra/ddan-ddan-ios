import Alamofire
import Foundation

public final class PetCatalogHeaderInterceptor: RequestInterceptor, @unchecked Sendable {
    public static let revisionHeader = "X-Pet-Catalog-Version"
    private let revisionProvider: any PetCatalogRevisionProviding

    public init(revisionProvider: any PetCatalogRevisionProviding = PetCatalogRevisionStore.shared) {
        self.revisionProvider = revisionProvider
    }

    public func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var request = urlRequest
        guard let path = request.url?.path, path.hasPrefix("/v1/") else {
            completion(.success(request))
            return
        }
        if path == PathString.Auth.login {
            request.setValue(nil, forHTTPHeaderField: Self.revisionHeader)
        } else {
            request.setValue(revisionProvider.currentRevision, forHTTPHeaderField: Self.revisionHeader)
        }
        completion(.success(request))
    }
}

final class DDanDDanRequestInterceptor: RequestInterceptor, @unchecked Sendable {
    private let catalog: PetCatalogHeaderInterceptor
    private let token: TokenInterceptor?

    init(catalog: PetCatalogHeaderInterceptor, token: TokenInterceptor?) {
        self.catalog = catalog
        self.token = token
    }

    func adapt(_ request: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        catalog.adapt(request, for: session) { [token] result in
            guard case let .success(adapted) = result, let token else {
                completion(result)
                return
            }
            token.adapt(adapted, for: session, completion: completion)
        }
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let token else { return completion(.doNotRetryWithError(error)) }
        token.retry(request, for: session, dueTo: error, completion: completion)
    }
}
