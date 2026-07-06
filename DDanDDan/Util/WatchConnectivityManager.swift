//
//  WatchConnectivityManager.swift
//  DDanDDan
//
//  Created by 이지희 on 10/25/24.
//

import WatchConnectivity
import SwiftUI
import OSLog

protocol WatchPetSyncing: Sendable {
    func syncPet(
        purposeKcal: Int,
        petType: String,
        level: Int,
        presentation: PetPresentation
    ) async
}

/// WatchConnectivity 관리하는 클래스, iOS - Watch 간 데이터 통신 담당
final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate, WatchPetSyncing, @unchecked Sendable {
    static let shared = WatchConnectivityManager()
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "DDanDDan",
        category: "WatchConnectivity"
    )
    @MainActor private var pendingPetMetadata: WatchPetSyncMetadata?
    @MainActor private var pendingPetFileURL: URL?
    @MainActor private var lastTransferredAssetIdentity: String?
    
    // MARK: - Init
    
    override private init() {
        super.init()
        // WatchConnectivity가 지원되는지 확인 후 세션을 설정하고 활성화
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // MARK: - Custom Method
    
    /// iPhone -> Watch 메세지 전송 함수
    /// - Parameters
    /// `message`: 전송할 키값과 데이터
    func sendMessage(message: [String: Any]) {
        print("Sending message to Watch")
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: { response in
                print("Message sent successfully: \(response)")
            }, errorHandler: { error in
                print("Error sending message: \(error.localizedDescription)")
            })
        } else {
            print("Watch is not reachable")
        }
    }
    
    func transferUserInfo(info: [String: Any]) {
        if WCSession.default.activationState == .activated {
            WCSession.default.transferUserInfo(info)
            print("User info transferred: \(info)")
        } else {
            print("WCSession is not activated")
        }
    }

    /// 현재 메인 펫 상태와 서버 카탈로그 SVG를 Watch에 동기화한다.
    /// 메타데이터는 최신 상태만 유지하고, SVG는 큰 데이터 전송에 적합한 transferFile을 사용한다.
    func syncPet(
        purposeKcal: Int,
        petType: String,
        level: Int,
        presentation: PetPresentation
    ) async {
        let imageURL = presentation.level?.imageURL
        let identity = [
            PetCatalogSnapshot.canonicalType(petType),
            String(level),
            imageURL?.absoluteString ?? "placeholder"
        ].joined(separator: "|")
        let metadata = WatchPetSyncMetadata(
            purposeKcal: purposeKcal,
            petType: petType,
            level: level,
            colorCode: presentation.colorCode ?? "#D0DAE4",
            assetIdentity: identity
        )

        let localURL: URL?
        if let imageURL {
            localURL = await PetAssetCache.shared.localURL(for: imageURL)
        } else {
            localURL = nil
        }
        await MainActor.run {
            pendingPetMetadata = metadata
            pendingPetFileURL = localURL
            flushPendingPetSyncIfPossible()
        }
    }

    @MainActor
    private func flushPendingPetSyncIfPossible() {
        let session = WCSession.default
        guard session.activationState == .activated,
              let metadata = pendingPetMetadata else { return }
        do {
            try session.updateApplicationContext(metadata.dictionary)
            if lastTransferredAssetIdentity != metadata.assetIdentity,
               let pendingPetFileURL {
                session.transferFile(pendingPetFileURL, metadata: metadata.dictionary)
                lastTransferredAssetIdentity = metadata.assetIdentity
            }
            self.pendingPetMetadata = nil
            self.pendingPetFileURL = nil
        } catch {
            Self.logger.error("Failed to update Watch context: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    
    // MARK: - 필수 구현 메서드 및 Delegate 메서드
    
    /// WCSessionDelegate 프로토콜 메서드 - 세션 활성화 완료 시 호출
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        print("WCSession activation completed with state: \(activationState)")
        Task { @MainActor [weak self] in self?.flushPendingPetSyncIfPossible() }
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor [weak self] in self?.flushPendingPetSyncIfPossible() }
    }

    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: (any Error)?) {
        guard error != nil,
              let identity = fileTransfer.file.metadata
                .flatMap(WatchPetSyncMetadata.init(dictionary:))?
                .assetIdentity else { return }
        Task { @MainActor [weak self] in
            guard self?.lastTransferredAssetIdentity == identity else { return }
            self?.lastTransferredAssetIdentity = nil
        }
    }
    
    
    /// 세션 비활성화되었을 때 호출
    func sessionDidBecomeInactive(_ session: WCSession) {    }
    
    /// 세션 비활성화 후 재활성화를 위해 호출
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    
    /// 워치로 부터 메시지를 받았을 때 처리하는 메서드
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {    }
    
}
