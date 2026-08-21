//
//  RemotePetAssetView.swift
//  DDanDDan
//
//  Created by Codex on 2026-07-01.
//

import SwiftUI
import SVGView
import Lottie

enum RemotePetAssetLoader {
    static func data(for url: URL, cache: any PetAssetCaching) async -> Data? {
        if let data = await cache.data(for: url) { return data }
        guard await cache.download(url) != nil else { return nil }
        return await cache.data(for: url)
    }
}

@MainActor
final class RemotePetAssetLoadState: ObservableObject {
    @Published private(set) var svg: String?
    @Published private(set) var animation: LottieAnimation?
    private(set) var currentIdentity: String?
    private(set) var readyIdentity: String?
    private(set) var failedIdentity: String?

    var hasReadyContent: Bool { svg != nil || animation != nil }

    func begin(identity: String) -> Bool {
        currentIdentity = identity
        return readyIdentity != identity
    }

    func commit(animation: LottieAnimation, identity: String) {
        guard currentIdentity == identity else { return }
        self.animation = animation
        svg = nil
        readyIdentity = identity
        failedIdentity = nil
    }

    func commit(svg: String, identity: String) {
        guard currentIdentity == identity else { return }
        self.svg = svg
        animation = nil
        readyIdentity = identity
        failedIdentity = nil
    }

    func fail(identity: String) {
        guard currentIdentity == identity else { return }
        failedIdentity = identity
        guard !hasReadyContent else { return }
        readyIdentity = nil
    }

    func showPlaceholder(identity: String) {
        currentIdentity = identity
        svg = nil
        animation = nil
        readyIdentity = nil
        failedIdentity = nil
    }
}

struct RemotePetAssetView: View {
    enum Motion { case normal, playEat }

    let presentation: PetPresentation
    let motion: Motion
    @StateObject private var loadState = RemotePetAssetLoadState()

    var body: some View {
        Group {
            if let animation = loadState.animation {
                LottieView(animation: animation).playing(loopMode: .loop)
            } else if let svg = loadState.svg {
                SVGView(string: svg).scaledToFit()
            } else {
                Image(.questionMark)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("펫 이미지를 불러올 수 없어요")
            }
        }
        .task(id: assetIdentity) { await load() }
    }

    private var assetIdentity: String {
        guard let level = presentation.level else { return "\(presentation.type)-placeholder" }
        let url = motion == .normal ? level.lottieDefaultUrl : level.lottiePlayEatUrl
        return "\(presentation.type)-\(level.level)-\(motion)-\(url)"
    }

    @MainActor
    private func load() async {
        let identity = assetIdentity
        guard loadState.begin(identity: identity) else { return }
        guard let level = presentation.level else {
            loadState.showPlaceholder(identity: identity)
            return
        }
        let lottieURL = motion == .normal ? level.defaultLottieURL : level.playEatLottieURL
        if let url = lottieURL,
           let data = await RemotePetAssetLoader.data(for: url, cache: PetAssetCache.shared),
           let decoded = await Task.detached(priority: .userInitiated, operation: {
               try? LottieAnimation.from(data: data)
           }).value {
            guard !Task.isCancelled, identity == assetIdentity else { return }
            loadState.commit(animation: decoded, identity: identity)
            return
        }
        guard !Task.isCancelled, identity == assetIdentity else { return }
        if let url = lottieURL { await PetAssetCache.shared.invalidate(url) }
        if let url = level.imageURL,
           let data = await RemotePetAssetLoader.data(for: url, cache: PetAssetCache.shared) {
            let value = String(data: data, encoding: .utf8)
            guard !Task.isCancelled, identity == assetIdentity else { return }
            if value?.lowercased().contains("<svg") == true {
                loadState.commit(svg: value ?? "", identity: identity)
                return
            }
            else { await PetAssetCache.shared.invalidate(url) }
        }
        guard !Task.isCancelled, identity == assetIdentity else { return }
        loadState.fail(identity: identity)
    }
}

@MainActor
struct CatalogPetView: View {
    @ObservedObject private var store = PetCatalogStore.shared
    let type: String
    let level: Int
    var motion: RemotePetAssetView.Motion = .normal

    var body: some View {
        RemotePetAssetView(
            presentation: .resolve(petType: type, petLevel: level, snapshot: store.snapshot),
            motion: motion
        )
    }
}

@MainActor
struct CatalogPetColor {
    static func resolve(type: String) -> Color {
        resolve(type: type, snapshot: PetCatalogStore.shared.snapshot)
    }

    static func resolve(type: String, snapshot: PetCatalogSnapshot) -> Color {
        let presentation = PetPresentation.resolve(petType: type, petLevel: 1, snapshot: snapshot)
        return resolve(presentation: presentation)
    }

    static func resolve(presentation: PetPresentation) -> Color {
        presentation.colorCode.map(Color.init(hex:)) ?? Color(.borderGray)
    }
}
