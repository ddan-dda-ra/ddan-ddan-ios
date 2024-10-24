//
//  WatchConnectivityManager.swift
//  DDanDDan
//
//  Created by 이지희 on 10/25/24.
//

import WatchConnectivity
import SwiftUI

/// WatchConnectivity 관리하는 클래스, iOS - Watch 간 데이터 통신 담당
final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

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
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending Message: \(error.localizedDescription)")
            }
        }
    }
    
    
    // MARK: - 필수 구현 메서드 및 Delegate 메서드
    
    /// WCSessionDelegate 프로토콜 메서드 - 세션 활성화 완료 시 호출
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        print("WCSession activation completed with state: \(activationState)")
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
