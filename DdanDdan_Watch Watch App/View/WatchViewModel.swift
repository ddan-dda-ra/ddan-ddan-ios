//
//  WatchViewModel.swift
//  DdanDdan_Watch Watch App
//
//  Created by 이지희 on 10/25/24.
//

import SwiftUI
import Combine

final class WatchViewModel: ObservableObject {
    var cancellables = Set<AnyCancellable>()
    
    @Published var goalKcal: Int?
    @Published var currentKcal: Int
    @Published var currentKcalProgress: Double = 0.0
    @Published var viewConfig: (ImageResource, Color)?
    @Published var petSVG: String?
    @Published var showLoginAlert = false
    
    private let healthKitManager: HealthKitManager = .shared
    private let watchConnectivityManager: WatchConnectivityManager = .shared
    
    init(currentKcal: Int = 0) {
        self.currentKcal = currentKcal
        
        bindWatchApp()
        updateProgress()
    }
    
    
    func observeHealthKitData() {
        healthKitManager.observeActiveEnergyBurned { [weak self] newKcal, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.currentKcal = Int(newKcal)
                self.updateProgress()
            }
        }
    }
    
    /// 도달률 업데이트
    public func updateProgress() {
        currentKcalProgress = calculateProgress()
    }
    
    /// 목표 칼로리 도달 여부를 반환
    public var isGoalMet: Bool {
        return currentKcal >= goalKcal ?? 0
    }
    
    /// 서버 카탈로그 색상과 번들 폴백 이미지로 UI를 설정한다.
    public func configureUI(petType: String, level: Int, colorCode: String) -> (ImageResource, Color) {
        let fallbackImage = PetType(rawValue: petType)?.image(for: level) ?? .blueEgg
        return (fallbackImage, Color(hex: colorCode))
    }
    
    /// 도달률 계산
    private func calculateProgress() -> Double {
        if let goalKcal {
            guard goalKcal > 0 else { return 0.0 }
            return min(Double(currentKcal) / Double(goalKcal), 1.0)
        }
        return 0
    }
    
    private func bindWatchApp() {
        Publishers.CombineLatest3(
            watchConnectivityManager.$purposeKcal,
            watchConnectivityManager.$petType,
            watchConnectivityManager.$level
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] purposeKcal, petType, level in
            guard let self = self else { return }
            
            // 데이터 통합 처리
            self.goalKcal = Int(purposeKcal)
            self.viewConfig = self.configureUI(
                petType: petType,
                level: level,
                colorCode: self.watchConnectivityManager.colorCode
            )
            self.updateProgress()
        }
        .store(in: &cancellables)

        watchConnectivityManager.$colorCode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] colorCode in
                guard let self else { return }
                self.viewConfig = self.configureUI(
                    petType: self.watchConnectivityManager.petType,
                    level: self.watchConnectivityManager.level,
                    colorCode: colorCode
                )
            }
            .store(in: &cancellables)

        watchConnectivityManager.$petSVG
            .receive(on: DispatchQueue.main)
            .assign(to: &$petSVG)
    }
}
