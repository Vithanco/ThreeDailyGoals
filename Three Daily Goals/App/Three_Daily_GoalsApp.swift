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
    @State var model: TaskManagerViewModel

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
        self.container = sharedModelContainer(inMemory: enableTesting, withCloud: true)  // enableTesting -> inMemory
        if enableTesting {
            self._model = State(wrappedValue: dummyViewModel())
        } else {
            self._model = State(
                wrappedValue: TaskManagerViewModel(
                    modelContext: container.mainContext, preferences: CloudPreferences(testData: false),
                    isTesting: false))  // enableTesting -> testData
        }

        guard calendarManager.hasCalendarAccess else {
            debugPrint("No calendar access available")
            return
        }

    }

    var body: some Scene {
        WindowGroup {
            MainView(model: model)
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
        .environment(model)
        .environment(calendarManager)
        .commands {
            // Add a CommandMenu for saving tasks
            CommandGroup(after: .importExport) {
                model.exportButton
                model.importButton
                model.statsDialog
            }
            CommandGroup(replacing: .undoRedo) {
                model.undoButton
                model.redoButton
            }
            CommandGroup(replacing: .newItem) {
                model.addNewItemButton
                    .keyboardShortcut("n", modifiers: [.command])
            }
            CommandMenu("Three Daily Goals") {
                model.compassCheckButton
                    .keyboardShortcut("r", modifiers: [.command])
            }
        }
        #if os(macOS)  // see Toolbar for iOS way
            Settings {
                PreferencesView(model: model).frame(width: 450)
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
        model.addItem(item: reviewTask)
        model.infoMessage = "Review Task added from \(url)"
        model.showInfoMessage = true
    }

}
