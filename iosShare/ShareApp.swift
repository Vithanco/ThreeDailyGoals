//
//  ShareApp.swift
//  iosShare
//
//  Created by Klaus Kneupner on 17/09/2025.
//

import SwiftData
import SwiftUI
import tdgCoreShare

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

// This file provides a local alias for the tdgCoreShare.ShareExtensionView
// to maintain compatibility with the existing codebase structure
typealias ShareExtensionView = tdgCoreShare.ShareExtensionView

class ShareViewController: tdgCoreShare.ShareViewController {
    // This class inherits from tdgCoreShare.ShareViewController
    // and provides the macOS-specific implementation
}
