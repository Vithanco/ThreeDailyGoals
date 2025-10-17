//
//  Three_Daily_GoalsApp.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import EventKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import os
import tdgCoreMain
import TipKit

// Test data loader using TestStorage's default data
let defaultTestDataLoader: TestDataLoader = { timeProvider in
    return TestStorage.createDefaultTestData(timeProvider: timeProvider)
}

@main
struct Three_Daily_GoalsApp: App {

    let calendarManager = CalendarManager()
    @State var appComponents: AppComponents

    init() {
        var enableTesting = false
        #if DEBUG
            let commandLineArguments = CommandLine.arguments
            if commandLineArguments.contains("enable-testing")
                || ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil
            {
                enableTesting = true
            }
        #endif

        // Set up app components
        self._appComponents = State(wrappedValue: setupApp(isTesting: enableTesting, loaderForTests: defaultTestDataLoader))
        
        // Initialize TipKit only in production (not during testing)
        if !enableTesting {
            TipManager.shared.configureTips()
        }
        
        // Only initialize calendar access if the plan step is enabled
        let planStepEnabled = appComponents.preferences.isCompassCheckStepEnabled(stepId: "plan")
        if calendarManager.shouldRequestCalendarAccess(planStepEnabled: planStepEnabled) {
            calendarManager.initializeIfNeeded()
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .navigationTitle("Three Daily Goals")
                .onDisappear {
                    terminateApp()
                }
                .onOpenURL { url in
                    // Handle URL navigation and task creation
                    handleURL(url: url)
                }
        }
        .modelContainer(appComponents.modelContainer)
        .environment(calendarManager)
        .environment(appComponents.preferences)
        .environment(appComponents.uiState)
        .environment(appComponents.dataManager)
        .environment(appComponents.compassCheckManager)
        .environment(appComponents.timeProviderWrapper)
        .commands {
            // Add a CommandMenu for saving tasks
            CommandGroup(after: .importExport) {
                appComponents.uiState.exportButton
                appComponents.uiState.importButton
                appComponents.uiState.statsDialog
            }
            CommandGroup(replacing: .undoRedo) {
                appComponents.dataManager.undoButton
                appComponents.dataManager.redoButton
            }
            CommandGroup(replacing: .newItem) {
                appComponents.uiState.addNewItemButton
                    .keyboardShortcut("n", modifiers: [.command])
            }
            CommandMenu("Three Daily Goals") {
                appComponents.compassCheckManager.compassCheckButton
                    .keyboardShortcut("r", modifiers: [.command])
            }
        }
        #if os(macOS)  // see Toolbar for iOS way
            Settings {
                PreferencesView().frame(width: 450)
                    .environment(appComponents.preferences)
                    .environment(appComponents.dataManager)
                    .environment(appComponents.uiState)
                                    .environment(appComponents.compassCheckManager)
                .environment(appComponents.timeProviderWrapper)
            }
        #endif
    }

    @MainActor private func terminateApp() {
        appComponents.modelContainer.mainContext.processPendingChanges()
        #if os(macOS)
            NSApplication.shared.terminate(self)
        #endif
    }

    @MainActor func handleURL(url: URL) {
        // Handle widget URLs - open specific task or just open app
        if url.scheme == "three-daily-goals" {
            if url.host == "task" {
                // Extract UUID from path: three-daily-goals://task/{uuid}
                if let taskUUID = url.pathComponents.last {
                    if let task = appComponents.dataManager.findTask(withUuidString: taskUUID) {
                        appComponents.uiState.select(task)
                        return
                    } else {
                        appComponents.uiState.infoMessage = "Task not found: \(taskUUID)"
                        appComponents.uiState.showInfoMessage = true
                        return
                    }
                }
            } else if url.host == "app" {
                // Just open the app, no task creation
                return
            }
        }
        
        // Unknown URL scheme - just open the app
        // (Share extension handles task creation separately)
    }

}
