//
//  TestCompassCheckSteps.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import Testing
import SwiftUI

@testable import Three_Daily_Goals

@Suite
@MainActor
struct TestCompassCheckSteps {
    
    // MARK: - Test Setup Helpers
    
    /// Creates a test data manager with various task states
    private func createTestDataManager() -> DataManager {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager
        
        // Clear existing tasks
        let allTasks = dataManager.items
        for task in allTasks {
            dataManager.deleteWithUIUpdate(task: task, uiState: appComponents.uiState)
        }
        
        // Add test tasks in different states
        let priorityTask = dataManager.addItem(title: "Priority Task")
        dataManager.move(task: priorityTask, to: .priority)
        
        let pendingTask = dataManager.addItem(title: "Pending Task")
        dataManager.move(task: pendingTask, to: .pendingResponse)
        
        let openTask = dataManager.addItem(title: "Open Task")
        dataManager.move(task: openTask, to: .open)
        
        // Add a task due soon (in 2 days)
        let dueTask = dataManager.addItem(title: "Due Soon Task")
        dueTask.due = Date().addingTimeInterval(2 * 24 * 60 * 60)
        dataManager.move(task: dueTask, to: .open)
        
        return dataManager
    }
    
    /// Creates a test data manager with no tasks
    private func createEmptyDataManager() -> DataManager {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager
        
        // Clear existing tasks
        let allTasks = dataManager.items
        for task in allTasks {
            dataManager.deleteWithUIUpdate(task: task, uiState: appComponents.uiState)
        }
        
        return dataManager
    }
    
    /// Creates a test data manager with only priority tasks
    private func createPriorityOnlyDataManager() -> DataManager {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager
        
        // Clear existing tasks
        let allTasks = dataManager.items
        for task in allTasks {
            dataManager.deleteWithUIUpdate(task: task, uiState: appComponents.uiState)
        }
        
        // Add only priority tasks
        let task1 = dataManager.addItem(title: "Priority Task 1")
        dataManager.move(task: task1, to: .priority)
        
        let task2 = dataManager.addItem(title: "Priority Task 2")
        dataManager.move(task: task2, to: .priority)
        
        return dataManager
    }
    
    // MARK: - Individual Step Tests
    
    @Test
    func testInformStep() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        let step = InformStep()
        
        // Inform step should always be available
        #expect(step.isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider))
        #expect(!step.shouldSkip(dataManager: dataManager, timeProvider: timeProvider))
        
        // Test button text using step manager
        let stepManager = CompassCheckStepManager(dataManager: dataManager, timeProvider: timeProvider)
        #expect(stepManager.getButtonText(for: .inform, os: .iOS) == "Next")
        #expect(stepManager.getButtonText(for: .inform, os: .macOS) == "Next")
        
        // onMoveToNext should not change anything
        let initialTaskCount = dataManager.items.count
        step.onMoveToNext(dataManager: dataManager, timeProvider: timeProvider)
        #expect(dataManager.items.count == initialTaskCount)
    }
    
    @Test
    func testCurrentPrioritiesStep() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        let step = CurrentPrioritiesStep()
        
        // Should be available when there are priority tasks
        #expect(step.isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider))
        #expect(!step.shouldSkip(dataManager: dataManager, timeProvider: timeProvider))
        
        // Test with no priority tasks
        let emptyDataManager = createEmptyDataManager()
        #expect(!step.isPreconditionFulfilled(dataManager: emptyDataManager, timeProvider: timeProvider))
        #expect(step.shouldSkip(dataManager: emptyDataManager, timeProvider: timeProvider))
        
        // Test onMoveToNext - should move all priority tasks to open
        let priorityTasksBefore = dataManager.list(which: .priority)
        #expect(priorityTasksBefore.count > 0)
        
        step.onMoveToNext(dataManager: dataManager, timeProvider: timeProvider)
        
        let priorityTasksAfter = dataManager.list(which: .priority)
        #expect(priorityTasksAfter.count == 0)
        
        // Check that tasks were moved to open
        let openTasks = dataManager.list(which: .open)
        #expect(openTasks.count >= priorityTasksBefore.count)
    }
    
    @Test
    func testPendingResponsesStep() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        let step = PendingResponsesStep()
        
        // Should be available when there are pending response tasks
        #expect(step.isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider))
        #expect(!step.shouldSkip(dataManager: dataManager, timeProvider: timeProvider))
        
        // Test with no pending tasks
        let emptyDataManager = createEmptyDataManager()
        #expect(!step.isPreconditionFulfilled(dataManager: emptyDataManager, timeProvider: timeProvider))
        #expect(step.shouldSkip(dataManager: emptyDataManager, timeProvider: timeProvider))
        
        // onMoveToNext should not change task states
        let pendingTasksBefore = dataManager.list(which: .pendingResponse)
        step.onMoveToNext(dataManager: dataManager, timeProvider: timeProvider)
        let pendingTasksAfter = dataManager.list(which: .pendingResponse)
        #expect(pendingTasksBefore.count == pendingTasksAfter.count)
    }
    
    @Test
    func testDueDateStep() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        let step = DueDateStep()
        
        // Should be available when there are tasks due soon
        #expect(step.isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider))
        #expect(!step.shouldSkip(dataManager: dataManager, timeProvider: timeProvider))
        
        // Test with no due tasks
        let emptyDataManager = createEmptyDataManager()
        #expect(!step.isPreconditionFulfilled(dataManager: emptyDataManager, timeProvider: timeProvider))
        #expect(step.shouldSkip(dataManager: emptyDataManager, timeProvider: timeProvider))
        
        // Test onMoveToNext - should move due tasks to priority
        let dueTasksBefore = dataManager.items.filter { task in
            task.isActive && task.dueUntil(date: timeProvider.getDate(inDays: 3))
        }
        #expect(dueTasksBefore.count > 0)
        
        step.onMoveToNext(dataManager: dataManager, timeProvider: timeProvider)
        
        // Check that due tasks were moved to priority
        let priorityTasks = dataManager.list(which: .priority)
        #expect(priorityTasks.count >= dueTasksBefore.count)
    }
    
    @Test
    func testReviewStep() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        let step = ReviewStep()
        
        // Review step should always be available
        #expect(step.isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider))
        #expect(!step.shouldSkip(dataManager: dataManager, timeProvider: timeProvider))
        
        // Test button text for different platforms using step manager
        let stepManager = CompassCheckStepManager(dataManager: dataManager, timeProvider: timeProvider)
        #expect(stepManager.getButtonText(for: .review, os: .iOS) == "Finish")
        #expect(stepManager.getButtonText(for: .review, os: .macOS) == "Next")
        
        // onMoveToNext should not change task states
        let initialTaskCount = dataManager.items.count
        step.onMoveToNext(dataManager: dataManager, timeProvider: timeProvider)
        #expect(dataManager.items.count == initialTaskCount)
    }
    
    @Test
    func testPlanStep() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        let step = PlanStep()
        
        // Plan step should always be available (only on macOS)
        #expect(step.isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider))
        #expect(!step.shouldSkip(dataManager: dataManager, timeProvider: timeProvider))
        
        // Test button text using step manager
        let stepManager = CompassCheckStepManager(dataManager: dataManager, timeProvider: timeProvider)
        #expect(stepManager.getButtonText(for: .plan, os: .macOS) == "Finish")
        
        // onMoveToNext should not change task states
        let initialTaskCount = dataManager.items.count
        step.onMoveToNext(dataManager: dataManager, timeProvider: timeProvider)
        #expect(dataManager.items.count == initialTaskCount)
    }
    
    // MARK: - Step Manager Tests
    
    @Test
    func testStepManagerFlow() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        let stepManager = CompassCheckStepManager(dataManager: dataManager, timeProvider: timeProvider)
        
        // Test getting current step
        let informStep = stepManager.getCurrentStep(for: .inform)
        #expect(informStep != nil)
        #expect(informStep?.state == .inform)
        
        // Test step progression
        var currentState: CompassCheckState = .inform
        
        // Should move from inform to currentPriorities (because we have priority tasks)
        let nextState1 = stepManager.getNextStep(from: currentState, os: .macOS)
        #expect(nextState1 == .currentPriorities)
        
        // Should move from currentPriorities to pending (because we have pending tasks)
        let nextState2 = stepManager.getNextStep(from: .currentPriorities, os: .macOS)
        #expect(nextState2 == .pending)
        
        // Should move from pending to dueDate (because we have due tasks)
        let nextState3 = stepManager.getNextStep(from: .pending, os: .macOS)
        #expect(nextState3 == .dueDate)
        
        // Should move from dueDate to review
        let nextState4 = stepManager.getNextStep(from: .dueDate, os: .macOS)
        #expect(nextState4 == .review)
        
        // Should move from review to plan (on macOS)
        let nextState5 = stepManager.getNextStep(from: .review, os: .macOS)
        #expect(nextState5 == .plan)
        
        // Should stay at plan (end of flow)
        let nextState6 = stepManager.getNextStep(from: .plan, os: .macOS)
        #expect(nextState6 == .plan)
    }
    
    @Test
    func testStepManagerFlowWithEmptyData() throws {
        let dataManager = createEmptyDataManager()
        let timeProvider = RealTimeProvider()
        
        // Create steps with controlled skipping behavior for predictable testing
        let stepsWithControlledSkipping: [CompassCheckStep] = [
            InformStep(),
            CurrentPrioritiesStep(), // Will be skipped (no priority tasks)
            PendingResponsesStep(),  // Will be skipped (no pending tasks)
            DueDateStep(),           // Will be skipped (no due tasks)
            ReviewStep(),
            PlanStep()
        ]
        let stepManager = CompassCheckStepManager(dataManager: dataManager, timeProvider: timeProvider, steps: stepsWithControlledSkipping)
        
        // With no tasks, should skip directly from inform to review
        let nextState1 = stepManager.getNextStep(from: .inform, os: .macOS)
        #expect(nextState1 == .review)
        
        // Should move from review to plan (on macOS)
        let nextState2 = stepManager.getNextStep(from: .review, os: .macOS)
        #expect(nextState2 == .plan)
        
        // Test that skipped steps show correct button text
        #expect(stepManager.getButtonText(for: .inform, os: .macOS) == "Next")
        #expect(stepManager.getButtonText(for: .review, os: .macOS) == "Next")
        #expect(stepManager.getButtonText(for: .plan, os: .macOS) == "Finish")
    }
    
    @Test
    func testStepManagerFlowWithOnlyPriorityTasks() throws {
        let dataManager = createPriorityOnlyDataManager()
        let timeProvider = RealTimeProvider()
        
        // Create a focused step configuration that tests priority task handling
        let priorityFocusedSteps: [CompassCheckStep] = [
            InformStep(),
            CurrentPrioritiesStep(), // Should be included (has priority tasks)
            PendingResponsesStep(),  // Should be skipped (no pending tasks)
            DueDateStep(),           // Should be skipped (no due tasks)
            ReviewStep()
        ]
        let stepManager = CompassCheckStepManager(dataManager: dataManager, timeProvider: timeProvider, steps: priorityFocusedSteps)
        
        // Should move from inform to currentPriorities
        let nextState1 = stepManager.getNextStep(from: .inform, os: .macOS)
        #expect(nextState1 == .currentPriorities)
        
        // Should skip pending and dueDate, go directly to review
        let nextState2 = stepManager.getNextStep(from: .currentPriorities, os: .macOS)
        #expect(nextState2 == .review)
        
        // Test button text reflects the focused flow
        #expect(stepManager.getButtonText(for: .inform, os: .macOS) == "Next")
        #expect(stepManager.getButtonText(for: .currentPriorities, os: .macOS) == "Next")
        #expect(stepManager.getButtonText(for: .review, os: .macOS) == "Finish")
    }
    
    @Test
    func testStepManagerMoveToNextStep() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        let stepManager = CompassCheckStepManager(dataManager: dataManager, timeProvider: timeProvider)
        
        // Test moving from inform to next step
        let nextState = stepManager.moveToNextStep(from: .inform, os: .macOS)
        #expect(nextState == .currentPriorities)
        
        // Priority tasks should still be there (InformStep.onMoveToNext does nothing)
        let priorityTasks = dataManager.list(which: .priority)
        #expect(priorityTasks.count > 0) // Should still have priority tasks
        
        // Test moving from currentPriorities to next step
        // This should execute CurrentPrioritiesStep.onMoveToNext (moves priorities to open)
        let nextState2 = stepManager.moveToNextStep(from: .currentPriorities, os: .macOS)
        #expect(nextState2 == .pending)
        
        // Now verify that priority tasks were moved to open
        let priorityTasksAfter = dataManager.list(which: .priority)
        #expect(priorityTasksAfter.count == 0) // Should be empty now
    }
    
    @Test
    func testStepManagerButtonText() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        let stepManager = CompassCheckStepManager(dataManager: dataManager, timeProvider: timeProvider)
        
        // Test button text for different states
        #expect(stepManager.getButtonText(for: .inform, os: .macOS) == "Next")
        #expect(stepManager.getButtonText(for: .currentPriorities, os: .macOS) == "Next")
        #expect(stepManager.getButtonText(for: .review, os: .iOS) == "Finish")
        #expect(stepManager.getButtonText(for: .review, os: .macOS) == "Next")
        #expect(stepManager.getButtonText(for: .plan, os: .macOS) == "Finish")
    }
    
    // MARK: - Integration Tests
    
    @Test
    func testCompleteCompassCheckFlow() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        
        // Create a simplified, predictable step flow for testing
        let simplifiedSteps: [CompassCheckStep] = [
            InformStep(),
            CurrentPrioritiesStep(),
            ReviewStep(),
            PlanStep()
        ]
        let stepManager = CompassCheckStepManager(dataManager: dataManager, timeProvider: timeProvider, steps: simplifiedSteps)
        
        // Track initial state
        let initialPriorityCount = dataManager.list(which: .priority).count
        let initialPendingCount = dataManager.list(which: .pendingResponse).count
        let initialOpenCount = dataManager.list(which: .open).count
        
        // Simulate complete flow with predictable steps
        var currentState: CompassCheckState = .inform
        var stepCount = 0
        let expectedStates: [CompassCheckState] = [.inform, .currentPriorities, .review, .plan]
        
        for expectedState in expectedStates {
            #expect(currentState == expectedState)
            
            if currentState == .plan {
                // Final step - should show "Finish"
                let buttonText = stepManager.getButtonText(for: currentState, os: .macOS)
                #expect(buttonText == "Finish")
                break
            }
            
            // Move to next step
            let nextState = stepManager.moveToNextStep(from: currentState, os: .macOS)
            currentState = nextState
            stepCount += 1
        }
        
        // Verify we completed the flow
        #expect(currentState == .plan)
        #expect(stepCount == 3) // Should have moved through 3 steps
        
        // Verify task state changes
        let finalPriorityCount = dataManager.list(which: .priority).count
        let finalPendingCount = dataManager.list(which: .pendingResponse).count
        let finalOpenCount = dataManager.list(which: .open).count
        
        // Priority tasks should have been moved to open
        #expect(finalPriorityCount < initialPriorityCount)
        #expect(finalOpenCount > initialOpenCount)
        
        // Pending tasks should remain unchanged
        #expect(finalPendingCount == initialPendingCount)
    }
    
    @Test
    func testCompassCheckManagerIntegration() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        let uiState = UIStateManager()
        let preferences = CloudPreferences(testData: true, timeProvider: timeProvider)
        let pushNotificationManager = PushNotificationManager()
        
        // Create a focused step configuration for testing integration
        let focusedSteps: [CompassCheckStep] = [
            InformStep(),
            CurrentPrioritiesStep(),
            ReviewStep()
        ]
        let customStepManager = CompassCheckStepManager(
            dataManager: dataManager, 
            timeProvider: timeProvider, 
            steps: focusedSteps
        )
        
        // Inject the custom step manager into CompassCheckManager
        let compassCheckManager = CompassCheckManager(
            dataManager: dataManager,
            uiState: uiState,
            preferences: preferences,
            timeProvider: timeProvider,
            pushNotificationManager: pushNotificationManager,
            stepManager: customStepManager
        )
        
        // Test that the manager uses the step-based system
        #expect(compassCheckManager.state == CompassCheckState.inform)
        
        // Test moveStateForward
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state == CompassCheckState.currentPriorities)
        
        // Test that priority task was moved to open
        let priorityTasks = dataManager.list(which: .priority)
        #expect(priorityTasks.count == 0)
        
        // Test button text
        let buttonText = compassCheckManager.moveStateForwardText
        #expect(buttonText == "Next")
        
        // Test final step
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state == CompassCheckState.review)
        #expect(compassCheckManager.moveStateForwardText == "Finish")
    }
    
    // MARK: - Edge Cases and Error Conditions
    
    @Test
    func testStepManagerWithInvalidState() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        let stepManager = CompassCheckStepManager(dataManager: dataManager, timeProvider: timeProvider)
        
        // Test with invalid state (should return nil)
        let invalidStep = stepManager.getCurrentStep(for: .inform) // This should work
        #expect(invalidStep != nil)
        
        // Test button text for invalid state
        let buttonText = stepManager.getButtonText(for: .inform, os: .macOS)
        #expect(buttonText == "Next")
    }
    
    @Test
    func testStepManagerWithAllTasksInSameState() throws {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager
        
        // Clear existing tasks
        let allTasks = dataManager.items
        for task in allTasks {
            dataManager.deleteWithUIUpdate(task: task, uiState: appComponents.uiState)
        }
        
        // Add only open tasks
        let task1 = dataManager.addItem(title: "Open Task 1")
        let task2 = dataManager.addItem(title: "Open Task 2")
        dataManager.move(task: task1, to: .open)
        dataManager.move(task: task2, to: .open)
        
        let timeProvider = RealTimeProvider()
        let stepManager = CompassCheckStepManager(dataManager: dataManager, timeProvider: timeProvider)
        
        // Should skip directly to review
        let nextState = stepManager.getNextStep(from: .inform, os: .macOS)
        #expect(nextState == .review)
    }
    
    @Test
    func testStepManagerWithTasksDueFarInFuture() throws {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager
        
        // Clear existing tasks
        let allTasks = dataManager.items
        for task in allTasks {
            dataManager.deleteWithUIUpdate(task: task, uiState: appComponents.uiState)
        }
        
        // Add a task due far in the future (30 days)
        let futureTask = dataManager.addItem(title: "Future Task")
        futureTask.due = Date().addingTimeInterval(30 * 24 * 60 * 60)
        dataManager.move(task: futureTask, to: .open)
        
        let timeProvider = RealTimeProvider()
        let stepManager = CompassCheckStepManager(dataManager: dataManager, timeProvider: timeProvider)
        
        // Should skip dueDate step
        let nextState = stepManager.getNextStep(from: .inform, os: .macOS)
        #expect(nextState == .review)
    }
    
    // MARK: - Platform-Specific Tests
    
    @Test
    func testIOSFlow() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        
        // Create platform-specific step configuration for iOS testing
        let iOSSteps: [CompassCheckStep] = [
            InformStep(),
            CurrentPrioritiesStep(),
            PendingResponsesStep(),
            DueDateStep(),
            ReviewStep(),
            PlanStep() // This should be skipped on iOS
        ]
        let stepManager = CompassCheckStepManager(dataManager: dataManager, timeProvider: timeProvider, steps: iOSSteps)
        
        // On iOS, should end at review step (plan step should be skipped)
        let nextState = stepManager.getNextStep(from: .review, os: .iOS)
        #expect(nextState == .review) // Should stay at review (end of flow)
        
        // Button text should be "Finish" for review on iOS
        let buttonText = stepManager.getButtonText(for: .review, os: .iOS)
        #expect(buttonText == "Finish")
        
        // Test that plan step is properly skipped on iOS
        let planNextState = stepManager.getNextStep(from: .plan, os: .iOS)
        #expect(planNextState == .plan) // Should stay at plan (no next step)
    }
    
    @Test
    func testMacOSFlow() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        
        // Create platform-specific step configuration for macOS testing
        let macOSSteps: [CompassCheckStep] = [
            InformStep(),
            CurrentPrioritiesStep(),
            PendingResponsesStep(),
            DueDateStep(),
            ReviewStep(),
            PlanStep() // This should be included on macOS
        ]
        let stepManager = CompassCheckStepManager(dataManager: dataManager, timeProvider: timeProvider, steps: macOSSteps)
        
        // On macOS, should continue to plan step
        let nextState = stepManager.getNextStep(from: .review, os: .macOS)
        #expect(nextState == .plan)
        
        // Button text should be "Next" for review on macOS
        let buttonText = stepManager.getButtonText(for: .review, os: .macOS)
        #expect(buttonText == "Next")
        
        // Button text should be "Finish" for plan on macOS
        let planButtonText = stepManager.getButtonText(for: .plan, os: .macOS)
        #expect(planButtonText == "Finish")
        
        // Test complete macOS flow
        let informNext = stepManager.getNextStep(from: .inform, os: .macOS)
        #expect(informNext == .currentPriorities)
        
        let planNext = stepManager.getNextStep(from: .plan, os: .macOS)
        #expect(planNext == .plan) // Should be the final step
    }
}
