//
//  DailyTasks.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 18/12/2023.
//

import Foundation
import SwiftData
import os

fileprivate let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: DailyTasks.self)
)

@Model
final class DailyTasks: ObservableObject, Identifiable {
    var day: Date  = Date.now
    
    @Relationship(deleteRule: .nullify) var priorities: [TaskItem]? = [TaskItem]()

    
    init() {
    }
    
    var id: Date {
        return day
    }
}

func loadPriorities(modelContext: Storage) -> DailyTasks {
    let fetchDescriptor = FetchDescriptor<DailyTasks>()
    
    do {
        let days = try modelContext.fetch(fetchDescriptor)
        if days.count > 1 {
            logger.error("days has \(days.count) entries! Why?")
            for d in days {
                modelContext.delete(d)
            }
        }
        if let result = days.first {
            return result
        }
    }
    catch {
        logger.warning("no data available?")
    }
    let new = DailyTasks()
    modelContext.insert(new)
    return new
}
