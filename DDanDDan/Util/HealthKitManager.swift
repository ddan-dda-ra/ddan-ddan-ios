//
//  HealthKitManager.swift
//  DDanDDan
//
//  Created by hwikang on 7/13/24.
//

import Foundation
import HealthKit
import UserNotifications

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
        readAndReport(completion: completion)

        // HKObserverQuery의 completionHandler는 반드시 호출해야 한다.
        // 미호출 시 iOS가 백그라운드 전달 재시도(3회) 후 업데이트 전달을 중단한다.
        let query = HKObserverQuery(sampleType: energyBurnedType, predicate: nil) { [weak self] _, completionHandler, error in
            defer { completionHandler() }
            guard error == nil else { return }
            self?.readAndReport(completion: completion)
        }

        activeObserverQuery = query
        healthStore.execute(query)
        Task {
            await enableBackgroundMode()
        }
    }

    private func readAndReport(completion: @escaping (Double, Bool) -> Void) {
        readActiveEnergyBurned { [weak self] kcal, authorized in
            // 권한이 확인됐거나 유의미한 데이터가 있을 때만 App Group에 저장.
            // 권한 없거나 일시적으로 데이터가 비는 경우 0으로 덮어쓰지 않도록 방어.
            if authorized || kcal > 0 {
                self?.saveActivityData(energy: kcal)
            }
            completion(kcal, authorized)
        }
    }
    
    func enableBackgroundMode() async {
        guard let healthStore = healthStore else { return }
        
        do {
            try await healthStore.enableBackgroundDelivery(for: energyBurnedType, frequency: .hourly)
        } catch let error {
            print("Failed to enableBackgroundDelivery \(error)")
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
    func readActiveEnergyBurned(completion: @escaping (Double, Bool) -> Void) {
        guard let healthStore = healthStore else {
            completion(0, false)
            return
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: energyBurnedType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            var resultCount = 0.0
            var errorDenied = false

            if let hkError = error as? HKError {
                switch hkError.code {
                case .errorAuthorizationDenied, .errorNoData:
                    errorDenied = true
                default:
                    break
                }
            }

            if let sum = result?.sumQuantity() {
                resultCount = sum.doubleValue(for: HKUnit.kilocalorie())
            } else if let error {
                print("Failed to fetch active energy burned = \(error.localizedDescription)")
            }

            // 데이터가 들어왔으면 권한이 있다는 가장 강한 증거 → 다른 신호 무시.
            // 데이터가 없을 때만 errorDenied로 판단.
            let authorized: Bool
            if resultCount > 0 {
                authorized = true
            } else {
                authorized = !errorDenied
            }

            DispatchQueue.main.async {
                completion(resultCount, authorized)
            }
        }
        
        healthStore.execute(query)
    }
    
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
