import Combine
import XCTest
@testable import DDanDDan

final class PetCatalogTests: XCTestCase {
    func testFreshCatalogWaitsForEveryAssetBeforeSave() async {
        let response = PetCatalogResponse(revision: "fresh", pets: [item(type: "CAT", levels: [1, 2])])
        let storage = StorageSpy(value: nil)
        let cache = CacheSpy()
        let repository = PetCatalogRepository(network: NetworkStub(result: .success(response)), storage: storage, cache: cache)

        let result = await repository.sync()

        guard case .success = result else { return XCTFail("all assets should be ready") }
        let saveCount = await storage.saveCount
        let downloadCount = await cache.downloaded.count
        XCTAssertEqual(saveCount, 1)
        XCTAssertEqual(downloadCount, 6)
    }

    func testFreshCatalogAssetFailureBlocksSaveAndPublish() async {
        let response = PetCatalogResponse(revision: "fresh", pets: [item(type: "CAT", levels: [1])])
        let failedURL = URL(string: "https://a/1d.json")!
        let storage = StorageSpy(value: nil)
        let cache = CacheSpy(alwaysFail: [failedURL])
        let repository = PetCatalogRepository(network: NetworkStub(result: .success(response)), storage: storage, cache: cache)

        let result = await repository.sync()

        guard case .failure = result else { return XCTFail("failure should block bootstrap") }
        let saveCount = await storage.saveCount
        let stored = await storage.load()
        XCTAssertEqual(saveCount, 0)
        XCTAssertNil(stored)
    }

    func testFreshCatalogMalformedAssetURLBlocksSave() async {
        let malformedLevel = PetCatalogLevel(
            level: 1,
            imageUrl: "relative.svg",
            lottieDefaultUrl: "https://a/default.json",
            lottiePlayEatUrl: "https://a/play.json"
        )
        let response = PetCatalogResponse(
            revision: "malformed",
            pets: [.init(type: "CAT", name: "cat", colorCode: "#112233", displayOrder: 0, levels: [malformedLevel])]
        )
        let storage = StorageSpy(value: nil)
        let repository = PetCatalogRepository(
            network: NetworkStub(result: .success(response)),
            storage: storage,
            cache: CacheSpy()
        )

        guard case .failure(.invalidResponse) = await repository.sync() else {
            return XCTFail("malformed URL must invalidate the whole candidate")
        }
        let saveCount = await storage.saveCount
        let stored = await storage.load()
        XCTAssertEqual(saveCount, 0)
        XCTAssertNil(stored)
    }

    func testRevisionAssetFailurePreservesStoredCatalog() async {
        let old = PetCatalogResponse(revision: "old", pets: [item(type: "CAT", levels: [1], host: "old")])
        let new = PetCatalogResponse(revision: "new", pets: [item(type: "CAT", levels: [1], host: "new")])
        let storage = StorageSpy(value: old)
        let cache = CacheSpy(alwaysFail: [URL(string: "https://new/1.svg")!])
        let repository = PetCatalogRepository(network: NetworkStub(result: .success(new)), storage: storage, cache: cache)
        _ = await repository.loadLocal()

        guard case .failure = await repository.sync() else { return XCTFail("revision should not commit") }
        let stored = await storage.load()
        let saveCount = await storage.saveCount
        XCTAssertEqual(stored?.revision, "old")
        XCTAssertEqual(saveCount, 0)
    }

    func testCachedLaunchWaitsOnlyForSelectedMainPetAssets() async {
        let local = PetCatalogResponse(revision: "local", pets: [
            item(type: "CAT", levels: [1, 2]),
            item(type: "DOG", levels: [1])
        ])
        let storage = StorageSpy(value: local)
        let cache = CacheSpy()
        let repository = PetCatalogRepository(
            network: NetworkStub(result: .failure(.requestFailed("offline"))),
            storage: storage,
            cache: cache
        )

        guard case .success = await repository.prepareForMain(petType: "CAT", level: 2) else {
            return XCTFail("selected level assets should be downloaded")
        }
        let downloaded = await cache.downloaded
        XCTAssertEqual(downloaded, local.pets[0].levels[1].assetURLs)
    }

    @MainActor
    func testStoreDoesNotPublishSameSnapshotTwice() {
        let store = PetCatalogStore()
        let snapshot = PetCatalogSnapshot(revision: "same", pets: [item(type: "CAT", levels: [1])])
        var emissions = 0
        let cancellable = store.$snapshot.dropFirst().sink { _ in emissions += 1 }
        store.publish(snapshot)
        store.publish(snapshot)
        XCTAssertEqual(emissions, 1)
        withExtendedLifetime(cancellable) {}
    }

    @MainActor
    func testRemoteAssetStateKeepsReadyAWhileBLoadsAndRejectsStaleCommit() {
        let state = RemotePetAssetLoadState()
        XCTAssertTrue(state.begin(identity: "A"))
        state.commit(svg: "<svg>A</svg>", identity: "A")
        XCTAssertEqual(state.svg, "<svg>A</svg>")

        XCTAssertTrue(state.begin(identity: "B"))
        XCTAssertEqual(state.svg, "<svg>A</svg>", "ready A must remain visible while B loads")
        state.commit(svg: "<svg>stale A</svg>", identity: "A")
        XCTAssertEqual(state.svg, "<svg>A</svg>", "stale completion must not commit")
        state.commit(svg: "<svg>B</svg>", identity: "B")
        XCTAssertEqual(state.svg, "<svg>B</svg>")
        XCTAssertEqual(state.readyIdentity, "B")
    }

    @MainActor
    func testRemoteAssetStateKeepsReadyAWhenBTerminallyFails() {
        let state = RemotePetAssetLoadState()
        _ = state.begin(identity: "A")
        state.commit(svg: "<svg>A</svg>", identity: "A")
        _ = state.begin(identity: "B")

        state.fail(identity: "B")

        XCTAssertEqual(state.svg, "<svg>A</svg>")
        XCTAssertEqual(state.readyIdentity, "A")
        XCTAssertEqual(state.failedIdentity, "B")
    }

    func testDecodesContractWithoutRemovedFields() throws {
        let data = Data(##"{"revision":"r1","pets":[{"type":"CAT","name":"고양이","colorCode":"#112233","displayOrder":1,"levels":[{"level":1,"imageUrl":"https://a/1.svg","lottieDefaultUrl":"https://a/d.json","lottiePlayEatUrl":"https://a/p.json"}]}]}"##.utf8)
        let decoded = try JSONDecoder().decode(PetCatalogResponse.self, from: data)
        XCTAssertEqual(decoded.revision, "r1")
        XCTAssertEqual(decoded.pets.first?.levels.first?.level, 1)
    }

    func testJoinsByTypeAndSelectsHighestLevel() {
        let snapshot = PetCatalogSnapshot(revision: "1", pets: [item(type: "NEW", levels: [5, 1, 3])])
        XCTAssertEqual(PetPresentation.resolve(petType: "NEW", petLevel: 4, snapshot: snapshot).level?.level, 3)
        XCTAssertEqual(PetPresentation.resolve(petType: "NEW", petLevel: 5, snapshot: snapshot).level?.level, 5)
    }

    func testLevelAboveFiveUsesLevelFive() {
        let snapshot = PetCatalogSnapshot(revision: "1", pets: [item(type: "NEW", levels: [1, 5])])
        XCTAssertEqual(PetPresentation.resolve(petType: "NEW", petLevel: 99, snapshot: snapshot).level?.level, 5)
    }

    func testSelectsEachLevelOneThroughFive() {
        let snapshot = PetCatalogSnapshot(revision: "1", pets: [item(type: "CAT", levels: [1, 2, 3, 4, 5])])
        for level in 1...5 {
            XCTAssertEqual(PetPresentation.resolve(petType: "CAT", petLevel: level, snapshot: snapshot).level?.level, level)
        }
    }

    func testRelativeAndMalformedURLsFallBack() {
        let level = PetCatalogLevel(level: 1, imageUrl: "relative.svg", lottieDefaultUrl: "not-a-url", lottiePlayEatUrl: "ftp://a/p.json")
        let catalog = PetCatalogItem(type: "BAD", name: "bad", colorCode: "#112233", displayOrder: 0, levels: [level])
        let result = PetPresentation.resolve(petType: "BAD", petLevel: 1, snapshot: .init(revision: "1", pets: [catalog]))
        XCTAssertTrue(result.usesPlaceholder)
    }

    func testInvalidCatalogFallsBack() {
        let snapshot = PetCatalogSnapshot(revision: "1", pets: [item(type: "EMPTY", color: "oops", levels: [])])
        XCTAssertTrue(PetPresentation.resolve(petType: "UNKNOWN", petLevel: 1, snapshot: snapshot).usesPlaceholder)
        let invalid = PetPresentation.resolve(petType: "EMPTY", petLevel: 1, snapshot: snapshot)
        XCTAssertNil(invalid.colorCode)
        XCTAssertTrue(invalid.usesPlaceholder)
    }

    func testSameRevisionSkipsDownloadAndSave() async {
        let response = PetCatalogResponse(revision: "same", pets: [item(type: "CAT", levels: [1])])
        let storage = StorageSpy(value: response)
        let cache = CacheSpy(existing: PetCatalogSnapshot(revision: response.revision, pets: response.pets).assetURLs)
        let repository = PetCatalogRepository(network: NetworkStub(result: .success(response)), storage: storage, cache: cache)
        _ = await repository.loadLocal()
        _ = await repository.sync()
        let saveCount = await storage.saveCount
        let downloadCount = await cache.downloaded.count
        XCTAssertEqual(saveCount, 0)
        XCTAssertEqual(downloadCount, 0)
    }

    func testSameRevisionRetriesOnlyMissingFiles() async {
        let response = PetCatalogResponse(revision: "same", pets: [item(type: "CAT", levels: [1])])
        let storage = StorageSpy(value: response)
        let cache = CacheSpy()
        let repository = PetCatalogRepository(network: NetworkStub(result: .success(response)), storage: storage, cache: cache)
        _ = await repository.loadLocal()
        _ = await repository.sync()
        let count = await cache.downloaded.count
        XCTAssertEqual(count, 3)
    }

    func testFailedDownloadIsRetriedOnNextSameRevisionSync() async {
        let response = PetCatalogResponse(revision: "new", pets: [item(type: "CAT", levels: [1])])
        let urls = PetCatalogSnapshot(revision: response.revision, pets: response.pets).assetURLs
        let cache = CacheSpy(failOnce: urls)
        let repository = PetCatalogRepository(network: NetworkStub(result: .success(response)), storage: StorageSpy(value: nil), cache: cache)
        _ = await repository.sync()
        _ = await repository.sync()
        let attempts = await cache.attempts
        XCTAssertTrue(attempts.values.allSatisfy { $0 == 2 })
        XCTAssertEqual(attempts.count, 3)
    }

    func testRevisionChangeDownloadsOnlyChangedOrMissing() async {
        let old = PetCatalogResponse(revision: "1", pets: [item(type: "CAT", levels: [1], host: "old")])
        let new = PetCatalogResponse(revision: "2", pets: [item(type: "CAT", levels: [1], host: "new")])
        let storage = StorageSpy(value: old)
        let cache = CacheSpy()
        let repository = PetCatalogRepository(network: NetworkStub(result: .success(new)), storage: storage, cache: cache)
        _ = await repository.loadLocal()
        _ = await repository.sync()
        let saveCount = await storage.saveCount
        let downloadCount = await cache.downloaded.count
        XCTAssertEqual(saveCount, 1)
        XCTAssertEqual(downloadCount, 3)
    }

    func testRevisionChangeKeepsUnchangedAndDownloadsChangedPlusMissing() async {
        let oldLevel = PetCatalogLevel(level: 1, imageUrl: "https://a/image.svg", lottieDefaultUrl: "https://a/old.json", lottiePlayEatUrl: "https://a/play.json")
        let newLevel = PetCatalogLevel(level: 1, imageUrl: "https://a/image.svg", lottieDefaultUrl: "https://a/new.json", lottiePlayEatUrl: "https://a/play.json")
        let old = PetCatalogResponse(revision: "1", pets: [.init(type: "CAT", name: "cat", colorCode: "#112233", displayOrder: 0, levels: [oldLevel])])
        let new = PetCatalogResponse(revision: "2", pets: [.init(type: "CAT", name: "cat", colorCode: "#112233", displayOrder: 0, levels: [newLevel])])
        let imageURL = URL(string: oldLevel.imageUrl)!
        let cache = CacheSpy(existing: [imageURL])
        let repository = PetCatalogRepository(network: NetworkStub(result: .success(new)), storage: StorageSpy(value: old), cache: cache)
        _ = await repository.loadLocal()
        _ = await repository.sync()
        let downloaded = await cache.downloaded
        XCTAssertEqual(downloaded, [URL(string: newLevel.lottieDefaultUrl)!, URL(string: newLevel.lottiePlayEatUrl)!])
    }

    func testNetworkFailureKeepsLocalCatalog() async {
        let old = PetCatalogResponse(revision: "local", pets: [item(type: "CAT", levels: [1])])
        let repository = PetCatalogRepository(
            network: NetworkStub(result: .failure(.requestFailed("offline"))),
            storage: StorageSpy(value: old), cache: CacheSpy()
        )
        _ = await repository.loadLocal()
        let result = await repository.sync()
        if case .success = result { XCTFail("failure expected") }
        let local = await repository.loadLocal()
        XCTAssertEqual(local.revision, "local")
    }

    func testAtomicStorageRoundTrip() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storage = PetCatalogStorage(fileURL: directory.appendingPathComponent("catalog.json"))
        let expected = PetCatalogResponse(revision: "r2", pets: [item(type: "CAT", levels: [1, 5])])
        try await storage.save(expected)
        let loaded = await storage.load()
        XCTAssertEqual(loaded, expected)
    }

    func testConcurrentSyncIsSingleFlight() async {
        let response = PetCatalogResponse(revision: "new", pets: [item(type: "CAT", levels: [1])])
        let network = DelayedNetwork(response: response)
        let repository = PetCatalogRepository(network: network, storage: StorageSpy(value: nil), cache: CacheSpy())
        let revisions = await withTaskGroup(of: String?.self, returning: [String?].self) { group in
            for _ in 0..<8 {
                group.addTask {
                    guard case let .success(snapshot) = await repository.sync() else { return nil }
                    return snapshot.revision
                }
            }
            var values: [String?] = []
            for await value in group { values.append(value) }
            return values
        }
        let count = await network.callCount
        XCTAssertEqual(count, 1)
        XCTAssertEqual(revisions.count, 8)
        XCTAssertTrue(revisions.allSatisfy { $0 == "new" })
    }

    func testOlderResponseCannotOverwriteNewerLocalGeneration() async {
        let oldResponse = PetCatalogResponse(revision: "old-server", pets: [item(type: "OLD", levels: [1])])
        let newerLocal = PetCatalogResponse(revision: "new-local", pets: [item(type: "NEW", levels: [1])])
        let network = DelayedNetwork(response: oldResponse)
        let storage = StorageSpy(value: nil)
        let repository = PetCatalogRepository(network: network, storage: storage, cache: CacheSpy())
        let syncTask = Task { await repository.sync() }
        try? await Task.sleep(nanoseconds: 10_000_000)
        await storage.set(newerLocal)
        _ = await repository.loadLocal()
        _ = await syncTask.value
        let stored = await storage.load()
        XCTAssertEqual(stored?.revision, "new-local")
    }

    func testFeedResponseAppliesLatestStateAndReselectsLevelAsset() {
        let snapshot = PetCatalogSnapshot(revision: "1", pets: [item(type: "CAT", levels: [1, 2, 3, 4, 5])])
        let state = HomePetInteractionReducer.reduce(
            response: .init(petID: "pet-new", petType: "CAT", level: 4, expPercent: 12, foodQuantity: 7, toyQuantity: 8),
            catalog: snapshot
        )
        XCTAssertEqual(state.petID, "pet-new")
        XCTAssertEqual(state.petType, "CAT")
        XCTAssertEqual(state.level, 4)
        XCTAssertEqual(state.expPercent, 12)
        XCTAssertEqual(state.foodQuantity, 7)
        XCTAssertEqual(state.toyQuantity, 8)
        XCTAssertEqual(state.presentation.level?.level, 4)
        XCTAssertEqual(state.presentation.level?.imageUrl, "https://a/4.svg")
    }

    func testPlayResponseTypeAndLevelChangeSelectsNewCatalogAsset() {
        let snapshot = PetCatalogSnapshot(revision: "1", pets: [
            item(type: "CAT", levels: [1, 2]),
            item(type: "NEW_TYPE", levels: [1, 5], host: "new")
        ])
        let state = HomePetInteractionReducer.reduce(
            response: .init(petID: "changed", petType: "NEW_TYPE", level: 6, expPercent: 33, foodQuantity: 2, toyQuantity: 1),
            catalog: snapshot
        )
        XCTAssertEqual(state.petID, "changed")
        XCTAssertEqual(state.petType, "NEW_TYPE")
        XCTAssertEqual(state.level, 6)
        XCTAssertEqual(state.expPercent, 33)
        XCTAssertEqual(state.foodQuantity, 2)
        XCTAssertEqual(state.toyQuantity, 1)
        XCTAssertEqual(state.presentation.level?.level, 5)
        XCTAssertEqual(state.presentation.level?.imageUrl, "https://new/5.svg")
    }

    func testLoginBootstrapWithEmptyLocalWaitsForServerSnapshot() async {
        let response = PetCatalogResponse(revision: "login-r1", pets: [item(type: "CAT", levels: [1])])
        let cache = CacheSpy(existing: PetCatalogSnapshot(revision: response.revision, pets: response.pets).assetURLs)
        let repository = PetCatalogRepository(
            network: NetworkStub(result: .success(response)),
            storage: StorageSpy(value: nil),
            cache: cache
        )
        let result = await repository.bootstrapAfterAuthentication()
        guard case let .success(snapshot) = result else { return XCTFail("bootstrap should succeed") }
        XCTAssertEqual(snapshot.revision, "login-r1")
        XCTAssertEqual(snapshot.catalogByType["CAT"]?.name, "CAT")
    }

    func testOnDemandLoaderDownloadsCacheMissAndReadsData() async {
        let url = URL(string: "https://a/pet.svg")!
        let expected = Data("<svg></svg>".utf8)
        let cache = CacheSpy(downloadData: [url: expected])
        let loaded = await RemotePetAssetLoader.data(for: url, cache: cache)
        XCTAssertEqual(loaded, expected)
        let attempts = await cache.attempts[url]
        XCTAssertEqual(attempts, 1)
    }

    func testCanonicalizedTypeJoinTrimsAndUppercases() {
        let snapshot = PetCatalogSnapshot(revision: "1", pets: [item(type: "  cat  ", levels: [1])])
        let presentation = PetPresentation.resolve(petType: " Cat\n", petLevel: 1, snapshot: snapshot)
        XCTAssertEqual(presentation.type, "CAT")
        XCTAssertEqual(presentation.level?.level, 1)
    }

    @MainActor
    func testSignUpLoginWaitsForCatalogBootstrapAndRejectsLoginFailure() async {
        let response = PetCatalogResponse(revision: "signup", pets: [item(type: "CAT", levels: [1])])
        let catalog = SignUpCatalogStub(response: response)
        let successViewModel = SignUpViewModel(
            repository: SignUpRepositoryStub(loginResult: .success(makeLoginData())),
            catalogRepository: catalog
        )
        let didSetSuccessPet = await successViewModel.updatePet(petType: .pinkCat)
        XCTAssertTrue(didSetSuccessPet)
        let loginSucceeded = await successViewModel.login()
        let successSyncCount = await catalog.syncCount
        XCTAssertTrue(loginSucceeded)
        XCTAssertEqual(successSyncCount, 1)

        let failedCatalog = SignUpCatalogStub(response: response)
        let failureViewModel = SignUpViewModel(
            repository: SignUpRepositoryStub(loginResult: .failure(.requestFailed("login failed"))),
            catalogRepository: failedCatalog
        )
        let loginFailed = await failureViewModel.login()
        let failedSyncCount = await failedCatalog.syncCount
        XCTAssertFalse(loginFailed)
        XCTAssertEqual(failedSyncCount, 0)

        let bootstrapFailure = SignUpCatalogStub(result: .failure(.requestFailed("catalog failed")))
        let bootstrapFailureViewModel = SignUpViewModel(
            repository: SignUpRepositoryStub(loginResult: .success(makeLoginData())),
            catalogRepository: bootstrapFailure
        )
        let didSetFailurePet = await bootstrapFailureViewModel.updatePet(petType: .pinkCat)
        XCTAssertTrue(didSetFailurePet)
        let bootstrapFailed = await bootstrapFailureViewModel.login()
        let bootstrapFailureSyncCount = await bootstrapFailure.syncCountValue()
        XCTAssertFalse(bootstrapFailed)
        XCTAssertEqual(bootstrapFailureSyncCount, 1)

        let emptyBootstrap = SignUpCatalogStub(response: .init(revision: "empty", pets: []))
        let emptyViewModel = SignUpViewModel(
            repository: SignUpRepositoryStub(loginResult: .success(makeLoginData())),
            catalogRepository: emptyBootstrap
        )
        let didSetEmptyPet = await emptyViewModel.updatePet(petType: .pinkCat)
        XCTAssertTrue(didSetEmptyPet)
        let emptySucceeded = await emptyViewModel.login()
        let emptySyncCount = await emptyBootstrap.syncCountValue()
        XCTAssertFalse(emptySucceeded)
        XCTAssertEqual(emptySyncCount, 1)
    }

    @MainActor
    func testSignUpReadinessUsesSetMainPetInsteadOfStaleDefaults() async {
        UserDefaultValue.petType = "DOG"
        UserDefaultValue.level = 5
        let response = PetCatalogResponse(revision: "signup", pets: [item(type: "CAT", levels: [1])])
        let catalog = SignUpCatalogStub(response: response)
        let viewModel = SignUpViewModel(
            repository: SignUpRepositoryStub(loginResult: .success(makeLoginData())),
            catalogRepository: catalog
        )

        let didSetPet = await viewModel.updatePet(petType: .pinkCat)
        let didLogin = await viewModel.login()
        XCTAssertTrue(didSetPet)
        XCTAssertTrue(didLogin)

        let prepared = await catalog.preparedPet()
        XCTAssertEqual(prepared?.type, "CAT")
        XCTAssertEqual(prepared?.level, 1)
    }

    @MainActor
    func testSplashBootstrapFailureStaysOnSplashAndRetryCanEnterMain() async {
        let coordinator = AppCoordinator()
        let snapshot = PetCatalogSnapshot(revision: "ready", pets: [item(type: "CAT", levels: [1])])
        let catalog = RetryCatalogStub(snapshot: snapshot)
        let viewModel = SplashViewModel(
            coordinator: coordinator,
            homeRepository: SplashHomeRepositoryStub(),
            catalogRepository: catalog
        )

        await viewModel.performInitialSetup()
        guard case .failed = viewModel.bootstrapState else { return XCTFail("failure state must be visible") }
        XCTAssertEqual(coordinator.rootView, .splash)

        await viewModel.retryInitialSetup()
        await Task.yield()
        XCTAssertEqual(viewModel.bootstrapState, .idle)
        XCTAssertEqual(coordinator.rootView, .mainTab)
        let prepareCount = await catalog.prepareCount
        XCTAssertEqual(prepareCount, 2)
    }

    @MainActor
    func testFriendCardBackgroundResolverUsesPublishedCatalogColor() async {
        let store = PetCatalogStore()
        let before = FriendCardCatalogResolver.presentation(petType: "CAT", petLevel: 1, snapshot: store.snapshot)
        XCTAssertNil(before.colorCode)

        let catalog = PetCatalogSnapshot(revision: "1", pets: [item(type: "CAT", color: "#123456", levels: [1])])
        store.publish(catalog)
        let after = FriendCardCatalogResolver.presentation(petType: "CAT", petLevel: 1, snapshot: store.snapshot)
        XCTAssertEqual(after.colorCode, "#123456")
    }

    private func makeLoginData() -> LoginData {
        .init(
            accessToken: "access",
            refreshToken: "refresh",
            user: .init(
                id: "user",
                name: "name",
                purposeCalorie: 100,
                foodQuantity: 1,
                toyQuantity: 1,
                tickets: 0,
                setting: .init(isAppPushOn: true)
            ),
            isOnboardingComplete: true
        )
    }

    private func item(type: String, color: String = "#112233", levels: [Int], host: String = "a") -> PetCatalogItem {
        .init(type: type, name: type, colorCode: color, displayOrder: 0, levels: levels.map {
            .init(level: $0, imageUrl: "https://\(host)/\($0).svg", lottieDefaultUrl: "https://\(host)/\($0)d.json", lottiePlayEatUrl: "https://\(host)/\($0)p.json")
        })
    }
}

private struct NetworkStub: PetCatalogNetworking {
    let result: Result<PetCatalogResponse, NetworkError>
    func fetchCatalog() async -> Result<PetCatalogResponse, NetworkError> { result }
}

private actor SignUpCatalogStub: PetCatalogRepositoryProtocol {
    let result: Result<PetCatalogSnapshot, NetworkError>
    var syncCount = 0
    var prepared: (type: String, level: Int)?
    init(response: PetCatalogResponse) {
        self.result = .success(.init(revision: response.revision, pets: response.pets))
    }
    init(result: Result<PetCatalogSnapshot, NetworkError>) { self.result = result }
    func loadLocal() -> PetCatalogSnapshot { .empty }
    func sync() -> Result<PetCatalogSnapshot, NetworkError> {
        syncCount += 1
        return result
    }
    func prepareForMain(petType: String, level: Int) -> Result<PetCatalogSnapshot, NetworkError> {
        prepared = (petType, level)
        syncCount += 1
        return result
    }
    func preparedPet() -> (type: String, level: Int)? { prepared }
    func syncCountValue() -> Int { syncCount }
}

private actor RetryCatalogStub: PetCatalogRepositoryProtocol {
    let snapshot: PetCatalogSnapshot
    var prepareCount = 0
    init(snapshot: PetCatalogSnapshot) { self.snapshot = snapshot }
    func loadLocal() -> PetCatalogSnapshot { .empty }
    func sync() -> Result<PetCatalogSnapshot, NetworkError> { .success(snapshot) }
    func prepareForMain(petType: String, level: Int) -> Result<PetCatalogSnapshot, NetworkError> {
        prepareCount += 1
        return prepareCount == 1
            ? .failure(.requestFailed("temporary"))
            : .success(snapshot)
    }
}

private struct SplashHomeRepositoryStub: HomeRepositoryProtocol {
    func getUserInfo() async -> Result<HomeUserInfo, NetworkError> {
        .success(.init(id: "user", purposeCalorie: 100, foodQuantity: 1, toyQuantity: 1, tickets: 0))
    }
    func getMainPetInfo() async -> Result<MainPet, NetworkError> {
        .success(.init(mainPet: .init(id: "pet", type: "CAT", level: 1, expPercent: 0)))
    }
    func getPetArchive() async -> Result<PetArchiveModel, NetworkError> { .failure(.requestFailed("unused")) }
    func getSpecificPet(petId: String) async -> Result<Pet, NetworkError> { .failure(.requestFailed("unused")) }
    func updateMainPet(petId: String) async -> Result<MainPet, NetworkError> { .failure(.requestFailed("unused")) }
    func feedPet(petId: String) async -> Result<UserPetData, NetworkError> { .failure(.requestFailed("unused")) }
    func playPet(petId: String) async -> Result<UserPetData, NetworkError> { .failure(.requestFailed("unused")) }
    func addNewPet(petType: String) async -> Result<Pet, NetworkError> { .failure(.requestFailed("unused")) }
    func addNewRandomPet() async -> Result<Pet, NetworkError> { .failure(.requestFailed("unused")) }
    func addNewGachaRandomPet() async -> Result<Pet, NetworkError> { .failure(.requestFailed("unused")) }
    func updateDailyKcal(calorie: Int) async -> Result<DailyUserData, NetworkError> { .failure(.requestFailed("unused")) }
}

private struct SignUpRepositoryStub: SignUpRepositoryProtocol {
    let loginResult: Result<LoginData, NetworkError>
    func update(name: String?, purposeCalorie: Int?) async -> Result<UserData, NetworkError> { .failure(.requestFailed("unused")) }
    func getKakaoToken() -> String? { "token" }
    func login(token: String, tokenType: String) async -> Result<LoginData, NetworkError> { loginResult }
    func addPet(petType: String) async -> Result<Pet, NetworkError> {
        .success(.init(id: "new-pet", type: petType, level: 1, expPercent: 0))
    }
    func setMainPet(petID: String) async -> Result<MainPet, NetworkError> {
        .success(.init(mainPet: .init(id: petID, type: "CAT", level: 1, expPercent: 0)))
    }
}

private actor DelayedNetwork: PetCatalogNetworking {
    let response: PetCatalogResponse
    var callCount = 0
    init(response: PetCatalogResponse) { self.response = response }
    func fetchCatalog() async -> Result<PetCatalogResponse, NetworkError> {
        callCount += 1
        try? await Task.sleep(nanoseconds: 50_000_000)
        return .success(response)
    }
}

private actor StorageSpy: PetCatalogStoring {
    var value: PetCatalogResponse?
    var saveCount = 0
    init(value: PetCatalogResponse?) { self.value = value }
    func load() -> PetCatalogResponse? { value }
    func save(_ catalog: PetCatalogResponse) { value = catalog; saveCount += 1 }
    func set(_ catalog: PetCatalogResponse) { value = catalog }
}

private actor CacheSpy: PetAssetCaching {
    var existing = Set<URL>()
    var downloaded = Set<URL>()
    var failOnce = Set<URL>()
    let alwaysFail: Set<URL>
    var attempts: [URL: Int] = [:]
    var storedData: [URL: Data]
    let downloadData: [URL: Data]
    init(existing: Set<URL> = [], failOnce: Set<URL> = [], alwaysFail: Set<URL> = [], downloadData: [URL: Data] = [:]) {
        self.existing = existing
        self.failOnce = failOnce
        self.alwaysFail = alwaysFail
        self.storedData = [:]
        self.downloadData = downloadData
    }
    func contains(_ url: URL) -> Bool { existing.contains(url) }
    func localURL(for url: URL) -> URL? { existing.contains(url) ? url : nil }
    func data(for url: URL) -> Data? { storedData[url] }
    func download(_ url: URL) -> URL? {
        attempts[url, default: 0] += 1
        if alwaysFail.contains(url) { return nil }
        if failOnce.remove(url) != nil { return nil }
        downloaded.insert(url)
        existing.insert(url)
        storedData[url] = downloadData[url]
        return url
    }
    func invalidate(_ url: URL) { existing.remove(url) }
}
