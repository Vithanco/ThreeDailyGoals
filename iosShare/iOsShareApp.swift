//
//  iOsShareApp.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/08/2025.
//

import SwiftData
import SwiftUI

@main
struct iOsShareApp: App {
    var body: some Scene {
        let sharedModelContainer = sharedModelContainer(inMemory: false, withCloud: false)
        let preferences = CloudPreferences(testData: false)

        WindowGroup {
            ShareExtensionView()
        }
        .modelContainer(sharedModelContainer)
        .environment(preferences)

    }
}
