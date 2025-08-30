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
        self._appComponents = State(wrappedValue: setupApp(isTesting: enableTesting))

        assert(appComponents.preferences != nil)
        guard calendarManager.hasCalendarAccess else {
            debugPrint("No calendar access available")
            return
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
                    // Parse the URL and create a task
                    createTaskFrom(url: url)
                }
        }
        .modelContainer(appComponents.modelContainer)
        .environment(calendarManager)
        .environment(appComponents.preferences)
        .environment(appComponents.uiState)
        .environment(appComponents.dataManager)
        .environment(appComponents.compassCheckManager)
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
            }
        #endif
    }

    @MainActor private func terminateApp() {
        appComponents.modelContainer.mainContext.processPendingChanges()
        #if os(macOS)
            NSApplication.shared.terminate(self)
        #endif
    }

    @MainActor func createTaskFrom(url: URL) {
        let reviewTask = TaskItem()
        reviewTask.title = "review" + url.lastPathComponent
        reviewTask.url = url.absoluteString
        appComponents.dataManager.addItem(item: reviewTask)
        appComponents.uiState.infoMessage = "Review Task added from \(url)"
        appComponents.uiState.showInfoMessage = true
    }

}
