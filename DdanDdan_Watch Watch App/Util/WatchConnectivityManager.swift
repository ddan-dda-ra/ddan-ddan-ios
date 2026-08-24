//
//  WatchConnectivityManager.swift
//  DdanDdan_Watch Watch App
//
//  Created by 이지희 on 10/25/24.
//

import Foundation
import SwiftUI
import WatchConnectivity

/// 워치 앱에서의 WatchConnectivity 설정
class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    private static let appGroup = "group.com.DdanDdan"
    private static let cachedAssetIdentityKey = "watchPetCachedAssetIdentity"
    
    @Published var purposeKcal: Double = 0.0
    @Published var petType: String = ""
    @Published var level: Int = 0
    @Published var colorCode: String = "#D0DAE4"
    @Published var petSVG: String?
    private var assetIdentity = ""
    private let defaults = UserDefaults(suiteName: appGroup)
    
    override private init() {
        super.init()
        restoreCachedState()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // MARK: - 필수 구현 메서드 및 Delegate 메서드
    
    /// 세션 활성화 완료 시 호출
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession activation completed with state: \(activationState)")
    }
    
    /// 워치로 iPhone으로부터 메시지를 받았을 때 처리하는 메서드
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        apply(dictionary: message)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        print("Received user info: \(userInfo)")
        apply(dictionary: userInfo)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(dictionary: applicationContext)
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard let metadata = file.metadata.flatMap(WatchPetSyncMetadata.init(dictionary:)),
              let data = try? Data(contentsOf: file.fileURL),
              let svg = String(data: data, encoding: .utf8),
              svg.lowercased().contains("<svg"),
              svg.lowercased().contains("</svg>") else { return }

        if let cacheURL = cachedAssetURL() {
            try? FileManager.default.createDirectory(
                at: cacheURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? data.write(to: cacheURL, options: .atomic)
        }
        defaults?.set(metadata.assetIdentity, forKey: Self.cachedAssetIdentityKey)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard assetIdentity == metadata.assetIdentity else { return }
            petSVG = svg
        }
    }

    private func apply(dictionary: [String: Any]) {
        guard let metadata = WatchPetSyncMetadata(dictionary: dictionary) else { return }
        persist(metadata)
        DispatchQueue.main.async { [weak self] in self?.apply(metadata) }
    }

    private func apply(_ metadata: WatchPetSyncMetadata) {
        if assetIdentity != metadata.assetIdentity {
            petSVG = cachedSVG(for: metadata.assetIdentity)
        } else if petSVG == nil {
            petSVG = cachedSVG(for: metadata.assetIdentity)
        }
        purposeKcal = Double(metadata.purposeKcal)
        petType = metadata.petType
        level = metadata.level
        colorCode = metadata.colorCode
        assetIdentity = metadata.assetIdentity
    }

    private func persist(_ metadata: WatchPetSyncMetadata) {
        metadata.dictionary.forEach { defaults?.set($0.value, forKey: $0.key) }
    }

    private func restoreCachedState() {
        guard let defaults,
              let metadata = WatchPetSyncMetadata(dictionary: defaults.dictionaryRepresentation()) else { return }
        apply(metadata)
    }

    private func cachedSVG(for identity: String) -> String? {
        guard defaults?.string(forKey: Self.cachedAssetIdentityKey) == identity,
              let cacheURL = cachedAssetURL(),
              let data = try? Data(contentsOf: cacheURL),
              let svg = String(data: data, encoding: .utf8),
              svg.lowercased().contains("<svg"),
              svg.lowercased().contains("</svg>") else { return nil }
        return svg
    }

    private func cachedAssetURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.appGroup)?
            .appendingPathComponent("PetCatalog/Watch", isDirectory: true)
            .appendingPathComponent("main-pet.svg")
    }
}
