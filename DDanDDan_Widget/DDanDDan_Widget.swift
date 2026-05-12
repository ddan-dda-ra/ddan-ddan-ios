//
//  DDanDDan_Widget.swift
//  DDanDDan_Widget
//
//  Created by 이지희 on 5/30/25.
//

import WidgetKit
import SwiftUI
import CryptoKit

/// App Group(`group.com.DdanDdan`) 의 카탈로그 JSON + 캐시 디렉토리에서 다운로드된 펫 이미지를 읽어온다.
/// 없거나 실패 시 nil — 위젯은 번들 ImageResource 로 폴백.
private func cachedWidgetPetImage(type: PetType, level: Int) -> UIImage? {
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

struct ActivityEntry: TimelineEntry {
    let date: Date
    let activeEnergy: Int
    let petType: String
    let petLevel: Int
}

struct ActivityProvider: TimelineProvider {
    func placeholder(in context: Context) -> ActivityEntry {
        ActivityEntry(
            date: Date(),
            activeEnergy: 0,
            petType: "",
            petLevel: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ActivityEntry) -> Void) {
        let entry = loadActivityData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ActivityEntry>) -> Void) {
        let entry = loadActivityData()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 15)))
        completion(timeline)
    }
    
    private func loadActivityData() -> ActivityEntry {
        let defaults = UserDefaults(suiteName: "group.com.DdanDdan")
        let kcal = Int(defaults?.double(forKey: "ActiveEnergy") ?? 0.0)
        let petType = defaults?.string(forKey: "petType") ?? ""
        let petLevel = defaults?.integer(forKey: "petLevel") ?? 0
        
        
        
        NSLog("read Current Kcal \(kcal) - in Widget")
        
        return ActivityEntry(
            date: Date(),
            activeEnergy: kcal,
            petType: petType,
            petLevel: petLevel
        )
    }
}

struct DDanDDan_WidgetEntryView : View {
    
    var activityEntry: ActivityProvider.Entry
    
    var body: some View {
        if activityEntry.petType == "" {
            Text("앱을 실행해서 활동 데이터를 가져오세요!")
                .font(.neoDunggeunmo12)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
            Link(destination: URL(string: "ddanddan://openApp")!) {
                Text("앱 열기")
                    .font(.caption)
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        } else {
            VStack {
                HStack {
                    kcalView
                    Spacer()
                }
                petImage(for: activityEntry)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                HStack(spacing: 6) {
                    WidgetButton(buttonType: .feed)
                    WidgetButton(buttonType: .toy)
                }
            }
            .padding(.vertical, 2)
            .containerBackground(for: .widget) {
                Color(.colorBackground)
            }
        }

    }
    
    private func petImage(for entry: ActivityEntry) -> Image {
        let petType = PetType(rawValue: entry.petType)
        if let type = petType,
           let cached = cachedWidgetPetImage(type: type, level: entry.petLevel) {
            return Image(uiImage: cached)
        }
        return Image(petType?.image(for: entry.petLevel) ?? .blueEgg)
    }

    var kcalView: some View {
        ZStack {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(activityEntry.activeEnergy))
                    .foregroundStyle(.colorTextHeadlinePrimary)
                    .font(.neoDunggeunmo14)
                Text("kcal")
                    .foregroundStyle(.colorTextBodySecondary)
                    .font(.neoDunggeunmo12)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(.colorDividerLevel02)
            .clipShape(RoundedRectangle(cornerRadius: 11))
        }
    }
    
}

enum ButtonType {
    case feed
    case toy
}

struct WidgetButton: View {
    var buttonType: ButtonType
    var body: some View {
        ZStack {
            Image(buttonType == .feed ? .iconFeed : .iconToy)
                .resizable()
                .scaledToFit()
                .frame(height: 24)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .background(.colorDividerLevel02)
                .clipShape(.rect(cornerRadius: 16))
        }
    }
}

struct DDanDDan_Widget: Widget {
    let kind: String = "DDanDDan_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ActivityProvider()) { entry in
            DDanDDan_WidgetEntryView(activityEntry: entry)
        }
        .supportedFamilies([.systemSmall])
    }
}

//#Preview(as: .systemSmall) {
//    DDanDDan_Widget()
//} timeline: {
//    ActivityEntry(date: .now, configuration: .smiley)
//    SimpleEntry(date: .now, configuration: .starEyes)
//}
//
