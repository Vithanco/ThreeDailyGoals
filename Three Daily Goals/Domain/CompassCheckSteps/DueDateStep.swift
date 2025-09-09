//
//  DueDateStep.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import SwiftUI

struct DueDateStep: CompassCheckStep {
    let state: CompassCheckState = .dueDate
    
    func isPreconditionFulfilled(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
        // Only show this step if there are tasks due soon
        return !getDueDateSoonTasks(dataManager: dataManager, timeProvider: timeProvider).isEmpty
    }
    
    @ViewBuilder
    func view(compassCheckManager: CompassCheckManager) -> AnyView {
        AnyView(CompassCheckDueDate())
    }
    
    func onMoveToNext(dataManager: DataManager, timeProvider: TimeProvider) {
        // Move all due soon tasks to priority
        let dueSoon = getDueDateSoonTasks(dataManager: dataManager, timeProvider: timeProvider)
        for task in dueSoon {
            dataManager.move(task: task, to: .priority)
        }
    }
    
    // Helper method to get tasks due soon (moved from CompassCheckManager)
    private func getDueDateSoonTasks(dataManager: DataManager, timeProvider: TimeProvider) -> [TaskItem] {
        let due = timeProvider.getDate(inDays: 3)
        let open = dataManager.items.filter({ $0.isActive }).filter({ $0.dueUntil(date: due) })
        return open.sorted()
    }
}
