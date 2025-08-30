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
    //    private let container = sharedModelContainer(inMemory: false, withCloud: false)
    //    @State private var preferences = CloudPreferences(testData: false)

    var body: some Scene {
        WindowGroup {
            // This is just a placeholder - the actual ShareViewController
            // will be instantiated by the system based on Info.plist configuration
            Text("Share Extension")
            //                .environment(preferences)
        }
        //        .modelContainer(container)
        #if os(macOS)
            .windowResizability(.contentSize)
        #endif
    }
}
