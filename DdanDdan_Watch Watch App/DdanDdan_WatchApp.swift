//
//  DdanDdan_WatchApp.swift
//  DdanDdan_Watch Watch App
//
//  Created by 이지희 on 10/24/24.
//

import SwiftUI

@main
struct DdanDdan_Watch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: WatchViewModel(goalKcal: 400))
        }
    }
}
