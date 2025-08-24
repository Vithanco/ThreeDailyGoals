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

    var container: ModelContainer
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
        self.container = sharedModelContainer(inMemory: enableTesting, withCloud: true)
        
        // Set up app components
        self._appComponents = State(wrappedValue: setupApp(isTesting: enableTesting))

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
        .modelContainer(container)
        .environment(calendarManager)
        .environment(appComponents.preferences)
        .environment(appComponents.uiState)
        .environment(appComponents.dataManager)
        .commands {
            let commands = AppCommands(appComponents: appComponents)
            // Add a CommandMenu for saving tasks
            CommandGroup(after: .importExport) {
                commands.exportButton
                commands.importButton
                commands.statsDialog
            }
            CommandGroup(replacing: .undoRedo) {
                commands.undoButton
                commands.redoButton
            }
            CommandGroup(replacing: .newItem) {
                commands.addNewItemButton
                    .keyboardShortcut("n", modifiers: [.command])
            }
            CommandMenu("Three Daily Goals") {
                commands.compassCheckButton
                    .keyboardShortcut("r", modifiers: [.command])
            }
        }
        #if os(macOS)  // see Toolbar for iOS way
            Settings {
                PreferencesView().frame(width: 450)
            }
        #endif
    }

    @MainActor private func terminateApp() {
        container.mainContext.processPendingChanges()
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
