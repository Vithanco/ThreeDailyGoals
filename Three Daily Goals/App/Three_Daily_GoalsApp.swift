//
//  Three_Daily_GoalsApp.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import os
import EventKit

@main
struct Three_Daily_GoalsApp: App {
    
    var container : ModelContainer
    var calendar: EKEventStore
    @State var model: TaskManagerViewModel
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Three_Daily_GoalsApp.self)
    )
    
    init() {
        var enableTesting = false
#if DEBUG
        let commandLineArguments = CommandLine.arguments
        if commandLineArguments.contains("enable-testing") {
            enableTesting = true
        }
#endif
        self.container = sharedModelContainer(inMemory: enableTesting) // enableTesting -> inMemory
        if enableTesting {
            self._model = State(wrappedValue: dummyViewModel())
        } else {
            self._model = State(wrappedValue:TaskManagerViewModel(modelContext: container.mainContext, preferences: CloudPreferences(testData: false), isTesting: false)) // enableTesting -> testData
        }
        
        // Initialize the store.
        calendar = EKEventStore()

        // Request access to reminders.
        calendar.requestFullAccessToEvents { granted, error in
//            if error != nil {
//                self.calendar = nil
//            }
        }
    }
    
    
    
    var body: some Scene {
        WindowGroup {
            MainView(model: model)
                .navigationTitle("Three Daily Goals")
        }
        .modelContainer(container)
        .environment(model)
        .commands {
            // Add a CommandMenu for saving tasks
            CommandGroup(after: .importExport){
                model.exportButton
                model.importButton
                model.statsDialog
            }
            CommandGroup(replacing: .undoRedo) {
                model.undoButton
                model.redoButton
            }
        }
#if os(macOS) // see Toolbar for iOS way
        Settings {
            PreferencesView(model: model).frame(width: 450)
        }
#endif
    }
    
}
