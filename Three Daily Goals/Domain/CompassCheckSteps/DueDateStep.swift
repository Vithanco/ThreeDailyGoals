//
//  DueDateStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI

import tdgCoreMain

public struct DueDateStep: CompassCheckStep {
    public let id: String = "dueDate"
    public let name: String = "Due Date Check"
    public let description: String = "Automatically moves tasks with upcoming due dates to your priority list."
    public let isSilent: Bool = false
    
    @ViewBuilder
    public func view(compassCheckManager: CompassCheckManager) -> AnyView {
        AnyView(CompassCheckDueDate())
    }
    
    public func act(dataManager: DataManager, timeProvider: TimeProvider, preferences: CloudPreferences) {
        // Move all due soon tasks to priority
        let dueSoon = getDueDateSoonTasks(dataManager: dataManager, timeProvider: timeProvider)
        for task in dueSoon {
            dataManager.move(task: task, to: .priority)
        }
    }
    
    public func isApplicable(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // Only show this step if there are tasks due soon
        return !getDueDateSoonTasks(dataManager: dataManager, timeProvider: timeProvider).isEmpty
    }
    
    // Helper method to get tasks due soon (moved from CompassCheckManager)
    private func getDueDateSoonTasks(dataManager: DataManager, timeProvider: TimeProvider) -> [TaskItem] {
        let due = timeProvider.getDate(inDays: 3)
        let open = dataManager.allTasks.filter({ $0.isActive }).filter({ $0.dueUntil(date: due) })
        return open.sorted()
    }
}
