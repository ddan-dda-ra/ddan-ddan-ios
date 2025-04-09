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
    
    func observeActiveEnergyBurned(completion: @escaping (Double) -> Void) {
        guard let healthStore = healthStore else {
            completion(0)
            return
        }
        
       
        let query = HKObserverQuery(sampleType: energyBurnedType, predicate: nil) { fetchCalories, completionHandler, error in
            guard error == nil else { return }
            let goalKcal = UserDefaults.standard.integer(forKey: "purposeKcal")
            
            //TODO: UserDefaults error 수정 필요
            // 변화가 있을 때 새로운 데이터를 가져옴
            self.readActiveEnergyBurned { kcal in
                if Int(kcal) >= goalKcal {
                    self.sendGoalAchievedNotification()
                }
                completion(kcal)
            }
            
        } 
        
        healthStore.execute(query)
        Task {
            await enableBackgroundMode()
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

    
    func readActiveEnergyBurned(completion: @escaping (Double) -> Void) {
        guard let healthStore = healthStore else {
            completion(0)
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: energyBurnedType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            var resultCount = 0.0
            
            guard let result = result else {
                print("Failed to fetch active energy burned = \(String(describing: error?.localizedDescription))")
                completion(resultCount)
                return
            }
            
            if let sum = result.sumQuantity() {
                resultCount = sum.doubleValue(for: HKUnit.kilocalorie())
            }
            
            DispatchQueue.main.async {
                completion(resultCount)
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
    
}
