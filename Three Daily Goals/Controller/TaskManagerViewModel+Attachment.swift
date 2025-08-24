//
//  TaskManagerViewModel+Attachment.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 21/08/2025.
//

import Foundation
import SwiftData

extension TaskManagerViewModel {
    func purgeableItems(at date: Date = Date()) -> [TaskItem] {
        let dueTasks = try? dataManager.modelContext.fetch(
            FetchDescriptor<TaskItem>(predicate: #Predicate { task in
                task.attachments?.contains {
                    !$0.isPurged && $0.nextPurgePrompt != nil && $0.nextPurgePrompt! <= date
                } ?? false
            })
        )
        return dueTasks ?? []
    }

    func purgeableStoredBytesAll(at date: Date = Date()) -> Int {
        purgeableItems().reduce(0) { $0 + $1.purgeableStoredBytes(at: date) }
    }

    func totalStoredBytesAll() -> Int {
        (try? dataManager.modelContext.fetch(FetchDescriptor<TaskItem>()))?
            .reduce(0) { $0 + $1.totalStoredBytes } ?? 0
    }

    func totalOriginalBytesAll() -> Int {
        (try? dataManager.modelContext.fetch(FetchDescriptor<TaskItem>()))?
            .reduce(0) { $0 + $1.totalOriginalBytes } ?? 0
    }
}
