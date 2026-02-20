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
@testable import tdgCoreWidget

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
            throw TestError.noUncategorisedTask
        }

        // Apply the quadrant tags
        task.applyEnergyEffortQuadrant(.highEnergyBigTask)
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
            throw TestError.noUncategorisedTask
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

    /// Test that only tasks older than the classification threshold are shown in EnergyEffortMatrix
    @Test
    func testEnergyEffortMatrixAgeFilter() throws {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager
        let timeProvider = appComponents.timeProvider

        // Clear existing test data tasks
        let allTasks = dataManager.allTasks
        for task in allTasks {
            dataManager.deleteWithUIUpdate(task: task, uiState: appComponents.uiState)
        }

        // Create a recent task (less than threshold) - should NOT be shown
        let recentTask = dataManager.addAndFindItem(
            title: "Recent Task",
            state: .open
        )
        recentTask.created = timeProvider.getDate(hoursPrior: hoursBeforeReadyForClassification - 25)

        // Create an old task (more than threshold) - SHOULD be shown
        let oldTask = dataManager.addAndFindItem(
            title: "Old Task",
            state: .open
        )
        oldTask.created = timeProvider.getDate(hoursPrior: hoursBeforeReadyForClassification + 5)

        // Create a very old task (well over threshold) - SHOULD be shown
        let veryOldTask = dataManager.addAndFindItem(
            title: "Very Old Task",
            state: .priority
        )
        veryOldTask.created = timeProvider.getDate(hoursPrior: hoursBeforeReadyForClassification + 45)

        // Verify all tasks exist
        #expect(dataManager.allTasks.contains { $0.id == recentTask.id })
        #expect(dataManager.allTasks.contains { $0.id == oldTask.id })
        #expect(dataManager.allTasks.contains { $0.id == veryOldTask.id })

        // Test the EnergyEffortMatrixStep.isApplicable logic
        let step = EnergyEffortMatrixStep()
        let now = timeProvider.now
        let cutoffDate = Calendar.current.date(byAdding: .hour, value: -hoursBeforeReadyForClassification, to: now) ?? now

        let uncategorizedTasks = dataManager.allTasks.filter { task in
            task.isActive
            && !task.hasCompleteEnergyEffortTags
            && task.created < cutoffDate
        }

        // Should show 2 tasks (old and very old), but not the recent task
        #expect(uncategorizedTasks.count == 2)
        #expect(uncategorizedTasks.contains { $0.id == oldTask.id })
        #expect(uncategorizedTasks.contains { $0.id == veryOldTask.id })
        #expect(!uncategorizedTasks.contains { $0.id == recentTask.id })

        // Verify the step is applicable when old tasks exist
        #expect(step.isApplicable(dataManager: dataManager, timeProvider: timeProvider))
    }

    /// Test that EnergyEffortMatrix step is not applicable when only recent tasks exist
    @Test
    func testEnergyEffortMatrixNotApplicableForRecentTasks() throws {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager
        let timeProvider = appComponents.timeProvider

        // Clear existing tasks
        let allTasks = dataManager.allTasks
        for task in allTasks {
            dataManager.deleteWithUIUpdate(task: task, uiState: appComponents.uiState)
        }

        // Create only recent tasks (all less than threshold)
        let recentTask1 = dataManager.addAndFindItem(
            title: "Recent Task 1",
            state: .open
        )
        recentTask1.created = timeProvider.getDate(hoursPrior: hoursBeforeReadyForClassification - 35)

        let recentTask2 = dataManager.addAndFindItem(
            title: "Recent Task 2",
            state: .priority
        )
        recentTask2.created = timeProvider.getDate(hoursPrior: hoursBeforeReadyForClassification - 15)

        // Verify tasks exist
        #expect(dataManager.allTasks.contains { $0.id == recentTask1.id })
        #expect(dataManager.allTasks.contains { $0.id == recentTask2.id })

        // Test that the step is NOT applicable
        let step = EnergyEffortMatrixStep()
        #expect(!step.isApplicable(dataManager: dataManager, timeProvider: timeProvider))
    }

    /// Test that tasks exactly at the threshold are NOT shown (boundary test)
    @Test
    func testEnergyEffortMatrixBoundaryAtThreshold() throws {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager
        let timeProvider = appComponents.timeProvider

        // Clear existing tasks
        let allTasks = dataManager.allTasks
        for task in allTasks {
            dataManager.deleteWithUIUpdate(task: task, uiState: appComponents.uiState)
        }

        // Create a task exactly at the threshold
        let boundaryTask = dataManager.addAndFindItem(
            title: "Boundary Task",
            state: .open
        )
        boundaryTask.created = timeProvider.getDate(hoursPrior: hoursBeforeReadyForClassification)

        // Test the filter logic
        let now = timeProvider.now
        let cutoffDate = Calendar.current.date(byAdding: .hour, value: -hoursBeforeReadyForClassification, to: now) ?? now

        let uncategorizedTasks = dataManager.allTasks.filter { task in
            task.isActive
            && !task.hasCompleteEnergyEffortTags
            && task.created < cutoffDate
        }

        // Task at exactly the threshold should NOT be included (< not <=)
        #expect(!uncategorizedTasks.contains { $0.id == boundaryTask.id })
    }
}
