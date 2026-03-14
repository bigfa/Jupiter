//
//  JupiterApp.swift
//  Jupiter
//
//  Created by rich on 2026/2/5.
//

import SwiftUI

@main
struct JupiterApp: App {
    @StateObject private var proAccessViewModel = DownloadAccessViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await proAccessViewModel.prepare()
                }
        }
    }
}
