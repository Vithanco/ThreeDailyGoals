//
//  Three_Daily_GoalsApp.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import SwiftUI
import SwiftData

@main
struct Three_Daily_GoalsApp: App {
    var inMemory = false
    
    init() {
           #if DEBUG
           if CommandLine.arguments.contains("enable-testing") {
               inMemory = true
           }
           #endif
       }
    
    var body: some Scene {
        WindowGroup {
            ContentView(modelContext: sharedModelContainer(inMemory: false).mainContext)
        }
        .modelContainer(sharedModelContainer(inMemory: inMemory))
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
                                let items = try sharedModelContainer(inMemory: inMemory).mainContext.fetch(fetchDescriptor)
                                
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
                                sharedModelContainer(inMemory: inMemory).mainContext.undoManager?.undo()
                            }
                            .keyboardShortcut("z", modifiers: [.command])

                            Button("Redo") {
                                sharedModelContainer(inMemory: inMemory).mainContext.undoManager?.redo()
                            }
                            .keyboardShortcut("Z", modifiers: [.command, .shift])
                        }
                }
        Settings {
            SettingsView()
        }
    }
    
}
