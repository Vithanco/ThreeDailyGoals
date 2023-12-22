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
