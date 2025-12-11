//
//  TestEnergyEffortMatrixUI.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 2025-12-11.
//

import Foundation
import SwiftUI
import Testing

@testable import Three_Daily_Goals
@testable import tdgCoreMain

@Suite
@MainActor
struct TestEnergyEffortMatrixUI {

    /// Test that tapping a quadrant applies tags and removes task from uncategorized list
    @Test
    func testQuadrantTapAppliesTags() throws {
        // Create test data with uncategorized tasks
        let testDataLoader: TestDataLoader = { timeProvider in
            var tasks: [TaskItem] = []

            // Create tasks without Energy-Effort tags
            let task1 = TaskItem(title: "Uncategorized Task 1")
            task1.state = .open
            tasks.append(task1)

            let task2 = TaskItem(title: "Uncategorized Task 2")
            task2.state = .priority
            tasks.append(task2)

            return tasks
        }

        let appComponents = setupApp(isTesting: true, loaderForTests: testDataLoader)
        let dataManager = appComponents.dataManager

        // Get the uncategorized tasks
        let uncategorizedTasks = dataManager.allTasks.filter { task in
            task.isActive && !task.hasCompleteEnergyEffortTags
        }

        #expect(uncategorizedTasks.count == 2)

        // Simulate tapping on the "Deep Work" quadrant (high-energy, big-task)
        guard let task = uncategorizedTasks.first else {
            throw TestError("No uncategorized tasks found")
        }

        // Apply the quadrant tags
        task.applyEnergyEffortQuadrant(.urgentImportant)
        dataManager.save()

        // Verify tags were applied
        #expect(task.tags.contains("high-energy"))
        #expect(task.tags.contains("big-task"))

        // Verify task now has complete Energy-Effort tags
        #expect(task.hasCompleteEnergyEffortTags)

        // Verify task is no longer in uncategorized list
        let stillUncategorized = dataManager.allTasks.filter { t in
            t.isActive && !t.hasCompleteEnergyEffortTags
        }
        #expect(stillUncategorized.count == 1)
        #expect(!stillUncategorized.contains(where: { $0.id == task.id }))
    }

    /// Test that tasks in review screens should have swipe actions available
    @Test
    func testReviewScreenSwipeActionsAvailable() throws {
        let testDataLoader: TestDataLoader = { timeProvider in
            var tasks: [TaskItem] = []

            // Create tasks in different states
            let priorityTask = TaskItem(title: "Priority Task")
            priorityTask.state = .priority
            tasks.append(priorityTask)

            let openTask = TaskItem(title: "Open Task")
            openTask.state = .open
            tasks.append(openTask)

            return tasks
        }

        let appComponents = setupApp(isTesting: true, loaderForTests: testDataLoader)
        let dataManager = appComponents.dataManager

        // Get a task to test swipe actions
        let priorityTask = dataManager.list(which: .priority).first
        #expect(priorityTask != nil)

        // Verify the task can be moved to other states (swipe actions should be available)
        #expect(priorityTask?.canBeMovedToOpen == true)
        #expect(priorityTask?.canBeClosed == true)
        #expect(priorityTask?.canBeMovedToPendingResponse == true)

        // Test swipe action: move to open
        if let task = priorityTask {
            dataManager.move(task: task, to: .open)
            #expect(task.state == .open)
        }
    }

    /// Test that swipe actions work in EnergyEffortMatrix view
    @Test
    func testEnergyEffortMatrixSwipeActions() throws {
        // Create test data with uncategorized tasks
        let testDataLoader: TestDataLoader = { timeProvider in
            var tasks: [TaskItem] = []

            // Create tasks without Energy-Effort tags
            let task1 = TaskItem(title: "Task to Swipe")
            task1.state = .open
            tasks.append(task1)

            return tasks
        }

        let appComponents = setupApp(isTesting: true, loaderForTests: testDataLoader)
        let dataManager = appComponents.dataManager

        // Get the uncategorized task
        let uncategorizedTasks = dataManager.allTasks.filter { task in
            task.isActive && !task.hasCompleteEnergyEffortTags
        }

        #expect(uncategorizedTasks.count == 1)

        guard let task = uncategorizedTasks.first else {
            throw TestError("No uncategorized tasks found")
        }

        // Test that task has swipe action capabilities
        #expect(task.canBeClosed == true)
        #expect(task.canBeMovedToPendingResponse == true)

        // Test swipe action: close the task
        dataManager.move(task: task, to: .closed)
        #expect(task.state == .closed)

        // Verify closed task is no longer uncategorized (because it's not active)
        let stillUncategorized = dataManager.allTasks.filter { t in
            t.isActive && !t.hasCompleteEnergyEffortTags
        }
        #expect(stillUncategorized.isEmpty)
    }
}

struct TestError: Error {
    let message: String
    init(_ message: String) {
        self.message = message
    }
}
