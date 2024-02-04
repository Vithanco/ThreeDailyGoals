//
//  Three_Daily_GoalsApp.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import SwiftUI
import SwiftData
import os

@main
struct Three_Daily_GoalsApp: App {
    
    var container : ModelContainer
    @State var model: TaskManagerViewModel
    private let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: String(describing: Three_Daily_GoalsApp.self)
        )
    
    init() {
        var inMemory = false
           #if DEBUG
           if CommandLine.arguments.contains("enable-testing") {
               inMemory = true
           }
           #endif
        self.container = sharedModelContainer(inMemory: inMemory)
        self._model = State(wrappedValue: TaskManagerViewModel(modelContext: container.mainContext, preferences: CloudPreferences(testData: false)))
       }
    
  
    
    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
        .modelContainer(container)
        .commands {
                    // Add a CommandMenu for saving tasks
            CommandGroup(after: .importExport){
                        Button("Export Tasks") {
//                            #if os(iOS)
//                            let fileManager = FileManager.default
//                                    let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true) as [String]
//                                    let filePath = "\(cachePath[0])/CloudKit"
//                                    do {
//                                        let contents = try fileManager.contentsOfDirectory(atPath: filePath)
//                                        for file in contents {
//                                            try fileManager.removeItem(atPath: "\(filePath)/\(file)")
//                                            print("Deleted: \(filePath)/\(file)") //Optional
//                                        }
//                                    } catch {
//                                        print("Errors!")
//                                    }
//                            #endif
                            let fetchDescriptor = FetchDescriptor<TaskItem>()
                            
                            do {
                                let items = try container.mainContext.fetch(fetchDescriptor)
                                
                                // Create an instance of JSONEncoder
                                let encoder = JSONEncoder()
                                // Convert your array into JSON data
                                let data = try encoder.encode(items)
                                // Specify the file path and name
                                let url = getDocumentsDirectory().appendingPathComponent("taskItems.json")
                                // Write the data to the file
                                try data.write(to: url)
                            } catch {
                                print("Failed to save task items: \(error)")
                            }
                            
                            

                        }
                        .keyboardShortcut("S", modifiers: [.command])
                    }
            CommandGroup(replacing: .undoRedo) {
                            Button("Undo") {
                               container.mainContext.undoManager?.undo()
                            }
                            .keyboardShortcut("z", modifiers: [.command])

                            Button("Redo") {
                                container.mainContext.undoManager?.redo()
                            }
                            .keyboardShortcut("Z", modifiers: [.command, .shift])
                        }
                }
        #if os(macOS) // see Toolbar for iOS way
        Settings {
            PreferencesView(model: model).frame(width: 450)
        }
        #endif
    }
    
}
