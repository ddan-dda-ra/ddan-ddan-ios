import Alamofire
import XCTest
@testable import DDanDDan

final class PetCatalogHeaderTests: XCTestCase {
    override func tearDown() {
        RequestCaptureURLProtocol.handler = nil
        super.tearDown()
    }

    func testAuthNetworkLoginAndReissueApplyExactHeaderPolicy() async {
        let expectation = expectation(description: "requests")
        expectation.expectedFulfillmentCount = 2
        let lock = NSLock()
        var captured: [URLRequest] = []
        RequestCaptureURLProtocol.handler = { request in
            lock.withLock { captured.append(request) }
            expectation.fulfill()
            return (HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!, Data())
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RequestCaptureURLProtocol.self]
        let manager = NetworkManager(
            withInterceptor: false,
            revisionProvider: RevisionSpy("stored-revision"),
            responseHeaderHandler: NoopHeaderHandler(),
            configuration: configuration,
            baseURL: "https://example.com"
        )
        let network = AuthNetwork(manager: manager)
        async let login = network.login(token: "token", tokenType: "KAKAO", deviceToken: nil)
        async let reissue = network.tokenReissue(refreshToken: "refresh")
        _ = await (login, reissue)
        await fulfillment(of: [expectation], timeout: 2)

        let requests = lock.withLock { captured }
        let loginRequest = requests.first { $0.url?.path == "/v1/auth/login" }
        let reissueRequest = requests.first { $0.url?.path == "/v1/auth/reissue" }
        XCTAssertNil(loginRequest?.value(forHTTPHeaderField: PetCatalogHeaderInterceptor.revisionHeader))
        XCTAssertEqual(reissueRequest?.value(forHTTPHeaderField: PetCatalogHeaderInterceptor.revisionHeader), "stored-revision")
    }

    func testLoginRemovesRevisionHeader() async throws {
        let interceptor = PetCatalogHeaderInterceptor(revisionProvider: RevisionSpy("r1"))
        var request = URLRequest(url: URL(string: "https://example.com/v1/auth/login")!)
        request.setValue("caller", forHTTPHeaderField: PetCatalogHeaderInterceptor.revisionHeader)
        let adapted = try await adapt(request, using: interceptor)
        XCTAssertNil(adapted.value(forHTTPHeaderField: PetCatalogHeaderInterceptor.revisionHeader))
    }

    func testGeneralAndLoginExtraRequestsIncludeStoredRevision() async throws {
        let interceptor = PetCatalogHeaderInterceptor(revisionProvider: RevisionSpy("2026-07-02T01:02:03Z"))
        for path in ["/v1/pets/me", "/v1/auth/login-extra"] {
            let request = URLRequest(url: URL(string: "https://example.com\(path)")!)
            let adapted = try await adapt(request, using: interceptor)
            XCTAssertEqual(adapted.value(forHTTPHeaderField: PetCatalogHeaderInterceptor.revisionHeader), "2026-07-02T01:02:03Z")
        }
    }

    func testReissueIncludesRevision() async throws {
        let interceptor = PetCatalogHeaderInterceptor(revisionProvider: RevisionSpy("revision"))
        let request = URLRequest(url: URL(string: "https://example.com/v1/auth/reissue")!)
        let adapted = try await adapt(request, using: interceptor)
        XCTAssertEqual(adapted.value(forHTTPHeaderField: PetCatalogHeaderInterceptor.revisionHeader), "revision")
    }

    func testMissingRevisionUsesEpoch() async throws {
        let suite = "revision-tests-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PetCatalogRevisionStore(defaults: defaults)
        let request = URLRequest(url: URL(string: "https://example.com/v1/users/me")!)
        let adapted = try await adapt(request, using: PetCatalogHeaderInterceptor(revisionProvider: store))
        XCTAssertEqual(adapted.value(forHTTPHeaderField: PetCatalogHeaderInterceptor.revisionHeader), PetCatalogRevisionStore.epochRevision)
    }

    func testFalseAndMissingResponseHeadersDoNotRefresh() async {
        let coordinator = RefreshSpy()
        let handler = PetCatalogResponseHeaderHandler(coordinator: coordinator)
        await handler.handle(response: response(headers: ["x-pEt-cAtAlOg-doWnLoAd-rEqUiReD": "false"]), requestURL: url("/v1/pets/me"))
        await handler.handle(response: response(headers: [:]), requestURL: url("/v1/pets/me"))
        let count = await coordinator.count
        XCTAssertEqual(count, 0)
    }

    func testTrueResponseHeaderRefreshesCaseInsensitively() async {
        let coordinator = RefreshSpy()
        let handler = PetCatalogResponseHeaderHandler(coordinator: coordinator)
        await handler.handle(response: response(headers: ["x-pEt-cAtAlOg-doWnLoAd-rEqUiReD": " TrUe "]), requestURL: url("/v1/pets/me"))
        let count = await coordinator.count
        XCTAssertEqual(count, 1)
    }

    func testCatalogTrueDoesNotRecursivelyRefresh() async {
        let coordinator = RefreshSpy()
        let handler = PetCatalogResponseHeaderHandler(coordinator: coordinator)
        await handler.handle(response: response(headers: [PetCatalogResponseHeaderHandler.downloadRequiredHeader: "true"]), requestURL: url("/v1/pets/catalog"))
        let count = await coordinator.count
        XCTAssertEqual(count, 0)
    }

    func testReissueTrueDoesNotRefreshCatalog() async {
        let coordinator = RefreshSpy()
        let handler = PetCatalogResponseHeaderHandler(coordinator: coordinator)
        await handler.handle(
            response: response(headers: [PetCatalogResponseHeaderHandler.downloadRequiredHeader: "true"]),
            requestURL: url("/v1/auth/reissue")
        )
        let count = await coordinator.count
        XCTAssertEqual(count, 0)
    }

    func testFailedRefreshIsSharedWithLate401ForSameAccessToken() async {
        let originalAccessToken = UserDefaultValue.accessToken
        let originalRefreshToken = UserDefaultValue.refreshToken
        defer {
            UserDefaultValue.accessToken = originalAccessToken
            UserDefaultValue.refreshToken = originalRefreshToken
        }
        let counter = Counter()
        let manager = TokenRefreshManager(
            reissue: { _ in
                await counter.started()
                try? await Task.sleep(nanoseconds: 100_000_000)
                return .failure(.requestFailed("expired refresh token"))
            },
            applyReissue: { _ in },
            logout: {}
        )
        UserDefaultValue.accessToken = "expired-access"
        UserDefaultValue.refreshToken = "expired-refresh"

        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await manager.refresh(failedRequestAuthorization: "Bearer expired-access")
                }
            }
            for await result in group {
                XCTAssertFalse(result)
            }
        }
        let lateResult = await manager.refresh(failedRequestAuthorization: "Bearer expired-access")
        let count = await counter.count

        XCTAssertFalse(lateResult)
        XCTAssertEqual(count, 1)
    }

    func testConcurrentTrueResponsesRefreshOnlyOnce() async throws {
        let counter = Counter()
        let coordinator = PetCatalogRefreshCoordinator {
            await counter.started()
            try? await Task.sleep(nanoseconds: 150_000_000)
        }
        let handler = PetCatalogResponseHeaderHandler(coordinator: coordinator)
        let trueResponse = response(headers: [PetCatalogResponseHeaderHandler.downloadRequiredHeader: "true"])
        let requestURL = url("/v1/pets/me")
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask { await handler.handle(response: trueResponse, requestURL: requestURL) }
            }
        }
        try await Task.sleep(nanoseconds: 250_000_000)
        let firstCount = await counter.count
        XCTAssertEqual(firstCount, 1)
        await handler.handle(response: trueResponse, requestURL: requestURL)
        try await Task.sleep(nanoseconds: 250_000_000)
        let secondCount = await counter.count
        XCTAssertEqual(secondCount, 2)
    }

    func testStorageCommitUpdatesSubsequentHeaderRevisionVerbatim() async throws {
        let suite = "revision-tests-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let revisionStore = PetCatalogRevisionStore(defaults: defaults)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let storage = PetCatalogStorage(fileURL: file, revisionStore: revisionStore)
        let revision = "2026-07-02T10:11:12.123+09:00"
        try await storage.save(.init(revision: revision, pets: []))

        let request = URLRequest(url: url("/v1/pets/me"))
        let adapted = try await adapt(request, using: PetCatalogHeaderInterceptor(revisionProvider: revisionStore))
        XCTAssertEqual(adapted.value(forHTTPHeaderField: PetCatalogHeaderInterceptor.revisionHeader), revision)
    }

    private func adapt(_ request: URLRequest, using interceptor: PetCatalogHeaderInterceptor) async throws -> URLRequest {
        try await withCheckedThrowingContinuation { continuation in
            interceptor.adapt(request, for: Session()) { continuation.resume(with: $0) }
        }
    }

    private func url(_ path: String) -> URL { URL(string: "https://example.com\(path)")! }
    private func response(headers: [String: String]) -> HTTPURLResponse {
        HTTPURLResponse(url: url("/v1/pets/me"), statusCode: 200, httpVersion: nil, headerFields: headers)!
    }
}

private struct RevisionSpy: PetCatalogRevisionProviding {
    let currentRevision: String
    init(_ value: String) { currentRevision = value }
}

private actor RefreshSpy: PetCatalogRefreshCoordinating {
    private(set) var count = 0
    func requestRefresh() { count += 1 }
}

private actor Counter {
    private(set) var count = 0
    func started() { count += 1 }
}

private struct NoopHeaderHandler: PetCatalogResponseHeaderHandling {
    func handle(response: HTTPURLResponse, requestURL: URL) async {}
}

private final class RequestCaptureURLProtocol: URLProtocol, @unchecked Sendable {
    static var handler: ((URLRequest) -> (HTTPURLResponse, Data))?
    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let handler = Self.handler else { return }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
