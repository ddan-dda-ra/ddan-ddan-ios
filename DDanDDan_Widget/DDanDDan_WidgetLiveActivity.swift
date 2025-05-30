//
//  DDanDDan_WidgetLiveActivity.swift
//  DDanDDan_Widget
//
//  Created by 이지희 on 5/30/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct DDanDDan_WidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct DDanDDan_WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DDanDDan_WidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension DDanDDan_WidgetAttributes {
    fileprivate static var preview: DDanDDan_WidgetAttributes {
        DDanDDan_WidgetAttributes(name: "World")
    }
}

extension DDanDDan_WidgetAttributes.ContentState {
    fileprivate static var smiley: DDanDDan_WidgetAttributes.ContentState {
        DDanDDan_WidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: DDanDDan_WidgetAttributes.ContentState {
         DDanDDan_WidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: DDanDDan_WidgetAttributes.preview) {
   DDanDDan_WidgetLiveActivity()
} contentStates: {
    DDanDDan_WidgetAttributes.ContentState.smiley
    DDanDDan_WidgetAttributes.ContentState.starEyes
}
