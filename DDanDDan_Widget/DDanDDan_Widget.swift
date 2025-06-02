//
//  DDanDDan_Widget.swift
//  DDanDDan_Widget
//
//  Created by 이지희 on 5/30/25.
//

import WidgetKit
import SwiftUI
struct ActivityEntry: TimelineEntry {
    let date: Date
    let activeEnergy: Int
    let petType: String
    let petLevel: Int
}

// 2️⃣ TimelineProvider 구현 (AppGroup 데이터 읽기)
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
    
//    @ObservedObject var viewModel: WatchViewModel
//    var entry: Provider.Entry
    var activityEntry: ActivityProvider.Entry
    
    var body: some View {
        if activityEntry.petType == "" {
            Text("앱을 실행해서 활동 데이터를 가져오세요!")
                                .font(.headline)
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
                Image(PetType(rawValue:activityEntry.petType)?.image(for: activityEntry.petLevel) ?? .blueEgg)
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

//
//extension ConfigurationAppIntent {
//    fileprivate static var smiley: ConfigurationAppIntent {
//        let intent = ConfigurationAppIntent()
//        intent.favoriteEmoji = "😀"
//        return intent
//    }
//    
//    fileprivate static var starEyes: ConfigurationAppIntent {
//        let intent = ConfigurationAppIntent()
//        intent.favoriteEmoji = "🤩"
//        return intent
//    }
//}

//#Preview(as: .systemSmall) {
//    DDanDDan_Widget()
//} timeline: {
//    ActivityEntry(date: .now, configuration: .smiley)
//    SimpleEntry(date: .now, configuration: .starEyes)
//}
//
