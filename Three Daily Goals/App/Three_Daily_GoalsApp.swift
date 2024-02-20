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

@main
struct Three_Daily_GoalsApp: App {
    
    var container : ModelContainer
    @State var model: TaskManagerViewModel
    @State var jsonExportDoc: JSONWriteOnlyDoc? = nil
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Three_Daily_GoalsApp.self)
    )
    
    init() {
        var enableTesting = false
#if DEBUG
        if CommandLine.arguments.contains("enable-testing") {
            enableTesting = true
        }
#endif
        self.container = sharedModelContainer(inMemory: enableTesting) // enableTesting -> inMemory
        if enableTesting {
            self._model = State(wrappedValue: dummyViewModel())
        } else {
            self._model = State(wrappedValue:TaskManagerViewModel(modelContext: container.mainContext, preferences: CloudPreferences(testData: false), isTesting: false)) // enableTesting -> testData
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
                Button("Export Tasks") {
                    jsonExportDoc = JSONWriteOnlyDoc(content: model.items)
                    model.showExportDialog = true
                }.keyboardShortcut("S", modifiers: [.command]).fileExporter(isPresented: $model.showExportDialog,
                                                document: jsonExportDoc,
                                                contentTypes:  [UTType.json],
                                                onCompletion:  { result in
                    switch result {
                        case .success(let url):
                            logger.info("Tasks exported to \(url)")
                        case .failure(let error):
                            logger.error("Exporting tasks led to \(error.localizedDescription)")
                    }})
                
                Button("Import Tasks") {
                    model.showImportDialog = true
                }.fileImporter(isPresented: $model.showImportDialog,
                                                allowedContentTypes:  [UTType.json],
                                                onCompletion: { result in
                    switch result {
                        case .success(let url):
                            // Ensure we have permission to access the file
                            let gotAccess = url.startAccessingSecurityScopedResource()
                            if gotAccess {
                                model.importTasks(url: url)
                                // Remember to release the file access when done
                                url.stopAccessingSecurityScopedResource()
                            }
                        case .failure(let error):
                            logger.error("Importing Tasks led to \(error.localizedDescription)")
                    }
                })
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
