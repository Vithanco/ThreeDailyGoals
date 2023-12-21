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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaskItem.self ,Comment.self, DailyTasks.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .commands {
                    // Add a CommandMenu for saving tasks
                    CommandMenu("File") {
                        Button("Export Tasks") {
                            
                            let fetchDescriptor = FetchDescriptor<TaskItem>()
                            
                            do {
                                let items = try sharedModelContainer.mainContext.fetch(fetchDescriptor)
                                
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
                }
    }
    
}
