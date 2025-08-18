//
//  iOsShareApp.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/08/2025.
//

import SwiftData
import SwiftUI

#if os(macOS)
    import AppKit
#endif

@main
struct ShareApp: App {
    private let container = sharedModelContainer(inMemory: false, withCloud: false)
    @State private var preferences = CloudPreferences(testData: false)

    var body: some Scene {
        WindowGroup {
            ShareExtensionView()
                .environment(preferences)
        }
        .modelContainer(container)
        #if os(macOS)
            .windowResizability(.contentSize)
        #endif
    }
}
