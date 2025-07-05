//
//  AppIntent.swift
//  DDanDDan_WatchWidget
//
//  Created by 이지희 on 6/2/25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }
}
