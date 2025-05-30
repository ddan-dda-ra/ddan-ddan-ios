//
//  DDanDDan_WidgetBundle.swift
//  DDanDDan_Widget
//
//  Created by 이지희 on 5/30/25.
//

import WidgetKit
import SwiftUI

@main
struct DDanDDan_WidgetBundle: WidgetBundle {
    var body: some Widget {
        DDanDDan_Widget()
        DDanDDan_WidgetControl()
        DDanDDan_WidgetLiveActivity()
    }
}
