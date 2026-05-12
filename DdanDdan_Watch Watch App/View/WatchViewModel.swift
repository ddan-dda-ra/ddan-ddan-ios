//
//  WatchViewModel.swift
//  DdanDdan_Watch Watch App
//
//  Created by 이지희 on 10/25/24.
//

import SwiftUI
import Combine
import CryptoKit

final class WatchViewModel: ObservableObject {
    var cancellables = Set<AnyCancellable>()

    @Published var goalKcal: Int?
    @Published var currentKcal: Int
    @Published var currentKcalProgress: Double = 0.0
    @Published var viewConfig: (ImageResource, Color)?
    /// App Group 캐시에서 로드된 펫 이미지. 메인 앱이 카탈로그를 sync해두면 여기로 들어오고,
    /// 없으면 nil → 뷰는 viewConfig 의 번들 ImageResource 폴백 사용.
    @Published var cachedPetImage: UIImage?
    @Published var showLoginAlert = false
    
    private let healthKitManager: HealthKitManager = .shared
    private let watchConnectivityManager: WatchConnectivityManager = .shared
    
    init(currentKcal: Int = 0) {
        self.currentKcal = currentKcal
        
        bindWatchApp()
        updateProgress()
    }
    
    
    func observeHealthKitData() {
        healthKitManager.observeActiveEnergyBurned { [weak self] newKcal in
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
    
    /// petType에 따른 UI 설정
    public func configureUI(petType: PetType, level: Int) -> (ImageResource, Color) {
        return (petType.image(for: level), petType.color)
    }

    /// App Group(`group.com.DdanDdan`) 의 카탈로그 JSON + 캐시 디렉토리에서
    /// 다운로드된 펫 이미지를 읽어온다. 없거나 실패 시 nil — 뷰는 번들 ImageResource 로 폴백.
    static func cachedPetImage(type: PetType, level: Int) -> UIImage? {
        let groupID = "group.com.DdanDdan"
        guard let userDefaults = UserDefaults(suiteName: groupID),
              let json = userDefaults.data(forKey: "petCatalogJSON") else {
            return nil
        }

        struct MinimalCatalog: Decodable {
            struct Item: Decodable {
                let type: String
                let levels: [String: Level]
            }
            struct Level: Decodable {
                let imageUrl: String
            }
            let pets: [Item]
        }

        guard let catalog = try? JSONDecoder().decode(MinimalCatalog.self, from: json),
              let item = catalog.pets.first(where: { $0.type == type.rawValue }),
              let urlString = item.levels[String(level)]?.imageUrl,
              let url = URL(string: urlString),
              let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            return nil
        }

        let filename = SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        let diskURL = container.appendingPathComponent("pet-assets").appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: diskURL) else { return nil }
        return UIImage(data: data)
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
            if let petTypeEnum = PetType(rawValue: petType) {
                self.viewConfig = self.configureUI(petType: petTypeEnum, level: level)
                // App Group 캐시에서 다운로드된 이미지를 읽어 우선 사용. 없으면 viewConfig 의 번들 폴백.
                self.cachedPetImage = Self.cachedPetImage(type: petTypeEnum, level: level)
            } else {
                self.cachedPetImage = nil
            }
            self.updateProgress()
        }
        .store(in: &cancellables)
    }
}
