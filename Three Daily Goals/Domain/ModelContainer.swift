//
//  ModelContainer.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 21/12/2023.
//

import Foundation
import SwiftData


typealias TaskSelector = ([TaskSection],[TaskItem],TaskItem?) -> Void
typealias OnSelectItem = (TaskItem) -> Void

fileprivate var container: ModelContainer? = nil

var sharedModelContainer: ModelContainer = {
    if let container = container {
        return container
    }
    
    let schema = Schema([
        TaskItem.self ,Comment.self, DailyTasks.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
        let result = try ModelContainer(for: schema, configurations: [modelConfiguration])
        DispatchQueue.main.async {
            result.mainContext.undoManager = UndoManager()
        }
        container = result
        return result
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
