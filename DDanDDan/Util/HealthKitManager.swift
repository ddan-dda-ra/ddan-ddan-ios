//
//  HealthKitManager.swift
//  DDanDDan
//
//  Created by hwikang on 7/13/24.
//

import Foundation
import HealthKit
import UserNotifications

// HealthKitManager는 iOS/watchOS 양 타겟에서 컴파일된다.
// 진단 텔레메트리(Crashlytics/Analytics/UIApplication)는 iOS 전용 의존성이므로
// Firebase가 링크되는 iOS 타겟에서만 컴파일한다(watch 타겟은 해당 모듈 미링크).
#if canImport(FirebaseCrashlytics)
import UIKit
import FirebaseCrashlytics
#endif

/// 활동에너지 read 호출의 출처. 텔레메트리에서 호출 경로를 구분하기 위해 사용한다.
enum HealthKitReadSource: String {
    case initRead          // observe 등록 직후 1회 read
    case observerCallback  // HKObserverQuery 콜백
    case foregroundReRead  // scenePhase .active 재조회
}

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private var healthStore: HKHealthStore?
    private let energyBurnedType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    private var activeObserverQuery: HKObserverQuery?
    
    private init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    func isAuthorized() -> Bool {
        guard let healthStore = healthStore else { return false }

        let stepType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let status = healthStore.authorizationStatus(for: stepType)

        return status == .sharingAuthorized
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard let healthStore = healthStore else {
            completion(false)
            return
        }
        
        let readTypes: Set = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            completion(success)
        }
    }
    
    /// 활성 에너지 변화를 관찰. callback은 (현재 칼로리, HealthKit 권한 허용 여부)를 함께 전달한다.
    /// 중복 호출 시 기존 ObserverQuery를 정리 후 재등록하여 중복 등록을 방지한다.
    func observeActiveEnergyBurned(completion: @escaping (Double, Bool) -> Void) {
        guard let healthStore = healthStore else {
            completion(0, false)
            return
        }

        // 기존 observer가 있으면 정리 (중복 등록 방지)
        if let existing = activeObserverQuery {
            healthStore.stop(existing)
            activeObserverQuery = nil
        }

        // 등록 시점에 한 번 즉시 read를 호출해 권한 상태와 현재 칼로리를 갱신한다.
        // (HKObserverQuery는 데이터 변경이 없으면 callback이 안 올 수 있음)
        readAndReport(source: .initRead, completion: completion)

        // HKObserverQuery의 completionHandler는 반드시 호출해야 한다.
        // 미호출 시 iOS가 백그라운드 전달 재시도(3회) 후 업데이트 전달을 중단한다.
        let query = HKObserverQuery(sampleType: energyBurnedType, predicate: nil) { [weak self] _, completionHandler, error in
            defer { completionHandler() }
            guard error == nil else { return }
            self?.readAndReport(source: .observerCallback, completion: completion)
        }

        activeObserverQuery = query
        healthStore.execute(query)
        Task {
            await enableBackgroundMode()
        }
    }

    private func readAndReport(source: HealthKitReadSource, completion: @escaping (Double, Bool) -> Void) {
        readActiveEnergyBurned(source: source) { [weak self] kcal, authorized in
            // 권한이 확인됐거나 유의미한 데이터가 있을 때만 App Group에 저장.
            // 권한 없거나 일시적으로 데이터가 비는 경우 0으로 덮어쓰지 않도록 방어.
            if authorized || kcal > 0 {
                self?.saveActivityData(energy: kcal)
            }
            completion(kcal, authorized)
        }
    }

    /// foreground 복귀 등 명시적 시점에 호출하는 단발 re-read.
    /// ObserverQuery를 재등록하지 않고 readActiveEnergyBurned만 1회 실행한다.
    /// (stop→execute 레이스·중복 등록 회피)
    func refreshActiveEnergy(source: HealthKitReadSource,
                             completion: @escaping (Double, Bool) -> Void) {
        guard healthStore != nil else {
            completion(0, false)
            return
        }
        readAndReport(source: source, completion: completion)
    }

    func enableBackgroundMode() async {
        guard let healthStore = healthStore else { return }

        do {
            try await healthStore.enableBackgroundDelivery(for: energyBurnedType, frequency: .hourly)
        } catch let error {
            #if canImport(FirebaseCrashlytics)
            // 백그라운드 전달 활성화 실패는 명백한 이상 → non-fatal + Analytics로 기록.
            let hkErrorCode = (error as? HKError)?.code.rawValue ?? -1
            AnalyticsManager.shared.logEvent(event: HealthKitEvent.backgroundDeliveryFailed(hkErrorCode: hkErrorCode))

            // UIApplication.backgroundRefreshStatus는 main-thread-only이므로 main hop 후 수집.
            let backgroundRefreshStatus = await MainActor.run {
                UIApplication.shared.backgroundRefreshStatus.rawValue
            }
            let crashlytics = Crashlytics.crashlytics()
            crashlytics.setCustomValue(hkErrorCode, forKey: "hk_error_code")
            crashlytics.setCustomValue(backgroundRefreshStatus, forKey: "hk_background_refresh_status")
            crashlytics.record(error: error)
            #endif
        }
    }

    
    /// 오늘 하루 활성 에너지 합계를 읽는다. callback은 (kcal, 권한 허용 여부).
    /// 권한 추론 우선순위:
    ///  1. 데이터가 실제로 들어왔으면(kcal > 0) 권한이 있다는 가장 강한 증거 → true.
    ///  2. 데이터가 없을 때만 HKError 기반으로 판단:
    ///     - HKError.errorAuthorizationDenied (read 권한에서는 거의 발생 안 함)
    ///     - HKError.errorNoData (read 권한 거부 시 실제로 발생하는 코드)
    /// NOTE: `authorizationStatus`는 write 권한 기준이라 read-only 요청 시
    /// 허용한 사용자에게도 `.sharingDenied`로 보이는 Apple 의도된 동작이 있어
    /// read 권한 추론에서는 사용하지 않는다.
    /// 첫날 운동 0인 사용자는 errorNoData로 인해 false positive가 날 수 있으나,
    /// 안내 툴팁 노출이라 사용자 영향은 제한적.
    func readActiveEnergyBurned(source: HealthKitReadSource = .observerCallback,
                                completion: @escaping (Double, Bool) -> Void) {
        guard let healthStore = healthStore else {
            completion(0, false)
            return
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: energyBurnedType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            var resultCount = 0.0
            var errorDenied = false

            let hkError = error as? HKError
            if let hkError {
                switch hkError.code {
                case .errorAuthorizationDenied, .errorNoData:
                    errorDenied = true
                default:
                    break
                }
            }

            if let sum = result?.sumQuantity() {
                resultCount = sum.doubleValue(for: HKUnit.kilocalorie())
            }

            // 데이터가 들어왔으면 권한이 있다는 가장 강한 증거 → 다른 신호 무시.
            // 데이터가 없을 때만 errorDenied로 판단.
            let authorized: Bool
            if resultCount > 0 {
                authorized = true
            } else {
                authorized = !errorDenied
            }

            // 진단 텔레메트리: 데이터 없음 + denied 계열(errorAuthorizationDenied)에서만 기록.
            // errorNoData(첫날 무운동과 모호)·정상 0은 침묵 → 맥락 의존 판정은 HomeViewModel이 담당.
            #if canImport(FirebaseCrashlytics)
            if resultCount == 0, let hkError, hkError.code == .errorAuthorizationDenied {
                self?.reportReadFailure(source: source, hkError: hkError)
            }
            #endif

            DispatchQueue.main.async {
                completion(resultCount, authorized)
            }
        }

        healthStore.execute(query)
    }

    #if canImport(FirebaseCrashlytics)
    /// read 권한 거부(denied) 계열 실패만 non-fatal + Analytics로 기록한다. (iOS 전용)
    private func reportReadFailure(source: HealthKitReadSource, hkError: HKError) {
        let hkErrorCode = hkError.code.rawValue
        AnalyticsManager.shared.logEvent(
            event: HealthKitEvent.readFailed(source: source.rawValue, hkErrorCode: hkErrorCode)
        )

        let crashlytics = Crashlytics.crashlytics()
        let authStatus = healthStore?.authorizationStatus(for: energyBurnedType).rawValue ?? -1
        crashlytics.setCustomValue(authStatus, forKey: "hk_auth_status")
        crashlytics.setCustomValue(hkErrorCode, forKey: "hk_error_code")
        crashlytics.setCustomValue(source.rawValue, forKey: "hk_source")
        crashlytics.record(error: hkError)
    }
    #endif
    
    func readThreeDaysTotalKcal(completion: @escaping (Double) -> Void) {
        guard let healthStore = healthStore else {
            completion(0)
            return
        }
        
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -3, to: endDate) else {
            completion(0)
            return
        }
        
        guard let energyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: energyBurnedType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, samples, error in
            guard let samples = samples as? [HKQuantitySample], error == nil else {
                completion(0)
                return
            }
            
            // 칼로리 합산
            let totalCalories = samples.reduce(0) { $0 + $1.quantity.doubleValue(for: HKUnit.kilocalorie()) }
            
            completion(totalCalories)
        }
        
        healthStore.execute(query)
    }
    
    private func sendGoalAchievedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "딴딴"
        content.body = "🎉 목표 칼로리 달성! 펫에게 줄 먹이를 받았어요."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "calorieGoalReached", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func saveActivityData(energy: Double) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.DdanDdan")
        sharedDefaults?.set(energy, forKey: "ActiveEnergy")
        sharedDefaults?.synchronize()
    }

}
