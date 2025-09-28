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
@testable import tdgCoreMain

@Suite
@MainActor
struct TestCompassCheckSteps {
    
    /// Helper function to create test preferences with plan step enabled
    private func createTestPreferencesWithPlanEnabled() -> CloudPreferences {
        let testPreferences = CloudPreferences(store: TestPreferences(), timeProvider: RealTimeProvider())
        
        // Debug: Check initial state
        let initialPlanState = testPreferences.isCompassCheckStepEnabled(stepId: "plan")
        print("DEBUG: Initial plan step state: \(initialPlanState)")
        
        // Enable the plan step
        testPreferences.setCompassCheckStepEnabled(stepId: "plan", enabled: true)
        
        // Debug: Check state after enabling
        let finalPlanState = testPreferences.isCompassCheckStepEnabled(stepId: "plan")
        print("DEBUG: Final plan step state: \(finalPlanState)")
        
        // Verify the setup is working
        assert(testPreferences.isCompassCheckStepEnabled(stepId: "plan") == true, "Plan step should be enabled in test setup")
        assert(testPreferences.isCompassCheckStepEnabled(stepId: "inform") == true, "Inform step should be enabled by default")
        
        return testPreferences
    }
    
    // MARK: - Test Setup Helpers
    
    /// Creates a test data loader with various task states
    private func createTestDataLoader() -> TestStorage.Loader {
        return { timeProvider in
            var tasks: [TaskItem] = []
            
            // Add test tasks in different states
            let priorityTask = TaskItem(title: "Priority Task")
            priorityTask.state = .priority
            tasks.append(priorityTask)
            
            let pendingTask = TaskItem(title: "Pending Task")
            pendingTask.state = .pendingResponse
            tasks.append(pendingTask)
            
            let openTask = TaskItem(title: "Open Task")
            openTask.state = .open
            tasks.append(openTask)
            
            // Add a task due soon (in 2 days)
            let dueTask = TaskItem(title: "Due Soon Task")
            dueTask.due = Date().addingTimeInterval(2 * 24 * 60 * 60)
            dueTask.state = .open
            tasks.append(dueTask)
            
            return tasks
        }
    }
    
    /// Creates a test data loader with no tasks
    private func createEmptyDataLoader() -> TestStorage.Loader {
        return { timeProvider in
            return [] // No tasks
        }
    }
    
    /// Creates a test data loader with only priority tasks
    private func createPriorityOnlyDataLoader() -> TestStorage.Loader {
        return { timeProvider in
            var tasks: [TaskItem] = []
            
            // Add only priority tasks
            let priorityTask1 = TaskItem(title: "Priority Task 1")
            priorityTask1.state = .priority
            tasks.append(priorityTask1)
            
            let priorityTask2 = TaskItem(title: "Priority Task 2")
            priorityTask2.state = .priority
            tasks.append(priorityTask2)
            
            return tasks
        }
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
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader())
        let dataManager = appComponents.dataManager
        let timeProvider = appComponents.timeProvider
        let step = InformStep()
        
        // Inform step should always be available
        #expect(step.isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider))
        #expect(!step.shouldSkip(dataManager: dataManager, timeProvider: timeProvider))
        
        // Test button text using compass check manager
        let compassCheckManager = appComponents.compassCheckManager
        #expect(compassCheckManager.moveStateForwardText == "Next")
        
        // act should not change anything
        let initialTaskCount = dataManager.items.count
        step.act(dataManager: dataManager, timeProvider: timeProvider, preferences: appComponents.preferences)
        #expect(dataManager.items.count == initialTaskCount)
    }
    
    @Test
    func testCurrentPrioritiesStep() throws {
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader())
        let dataManager = appComponents.dataManager
        let timeProvider = appComponents.timeProvider
        let step = CurrentPrioritiesStep()
        
        // Should be available when there are priority tasks
        #expect(step.isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider))
        #expect(!step.shouldSkip(dataManager: dataManager, timeProvider: timeProvider))
        
        // Test with no priority tasks
        let emptyDataManager = createEmptyDataManager()
        #expect(!step.isPreconditionFulfilled(dataManager: emptyDataManager, timeProvider: timeProvider))
        #expect(step.shouldSkip(dataManager: emptyDataManager, timeProvider: timeProvider))
        
        // Test act - should move all priority tasks to open
        let priorityTasksBefore = dataManager.list(which: .priority)
        #expect(priorityTasksBefore.count > 0)
        
        step.act(dataManager: dataManager, timeProvider: timeProvider, preferences: appComponents.preferences)
        
        let priorityTasksAfter = dataManager.list(which: .priority)
        #expect(priorityTasksAfter.count == 0)
        
        // Check that tasks were moved to open
        let openTasks = dataManager.list(which: .open)
        #expect(openTasks.count >= priorityTasksBefore.count)
    }
    
    @Test
    func testPendingResponsesStep() throws {
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader())
        let dataManager = appComponents.dataManager
        let timeProvider = appComponents.timeProvider
        let step = PendingResponsesStep()
        
        // Should be available when there are pending response tasks
        #expect(step.isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider))
        #expect(!step.shouldSkip(dataManager: dataManager, timeProvider: timeProvider))
        
        // Test with no pending tasks
        let emptyDataManager = createEmptyDataManager()
        #expect(!step.isPreconditionFulfilled(dataManager: emptyDataManager, timeProvider: timeProvider))
        #expect(step.shouldSkip(dataManager: emptyDataManager, timeProvider: timeProvider))
        
        // act should not change task states
        let pendingTasksBefore = dataManager.list(which: .pendingResponse)
        step.act(dataManager: dataManager, timeProvider: timeProvider, preferences: appComponents.preferences)
        let pendingTasksAfter = dataManager.list(which: .pendingResponse)
        #expect(pendingTasksBefore.count == pendingTasksAfter.count)
    }
    
    @Test
    func testDueDateStep() throws {
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader())
        let dataManager = appComponents.dataManager
        let timeProvider = appComponents.timeProvider
        let step = DueDateStep()
        
        // Should be available when there are tasks due soon
        #expect(step.isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider))
        #expect(!step.shouldSkip(dataManager: dataManager, timeProvider: timeProvider))
        
        // Test with no due tasks
        let emptyDataManager = createEmptyDataManager()
        #expect(!step.isPreconditionFulfilled(dataManager: emptyDataManager, timeProvider: timeProvider))
        #expect(step.shouldSkip(dataManager: emptyDataManager, timeProvider: timeProvider))
        
        // Test act - should move due tasks to priority
        let dueTasksBefore = dataManager.items.filter { task in
            task.isActive && task.dueUntil(date: timeProvider.getDate(inDays: 3))
        }
        #expect(dueTasksBefore.count > 0)
        
        step.act(dataManager: dataManager, timeProvider: timeProvider, preferences: appComponents.preferences)
        
        // Check that due tasks were moved to priority
        let priorityTasks = dataManager.list(which: .priority)
        #expect(priorityTasks.count >= dueTasksBefore.count)
    }
    
    @Test
    func testReviewStep() throws {
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader(), preferences: createTestPreferencesWithPlanEnabled())
        let dataManager = appComponents.dataManager
        let timeProvider = appComponents.timeProvider
        let step = ReviewStep()
        
        // Review step should always be available
        #expect(step.isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider))
        #expect(!step.shouldSkip(dataManager: dataManager, timeProvider: timeProvider))
        
        // Test button text for different platforms using compass check manager
        let compassCheckManager = appComponents.compassCheckManager
        // Set to review step for testing
        compassCheckManager.state = .inProgress(ReviewStep())
        #expect(compassCheckManager.moveStateForwardText == "Next") // Should be "Next" on macOS
        
        // act should not change task states
        let initialTaskCount = dataManager.items.count
        step.act(dataManager: dataManager, timeProvider: timeProvider, preferences: appComponents.preferences)
        #expect(dataManager.items.count == initialTaskCount)
    }
    
    @Test
    func testPlanStep() throws {
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader())
        let dataManager = appComponents.dataManager
        let timeProvider = appComponents.timeProvider
        let step = PlanStep()
        
        // Plan step should always be available (only on macOS)
        #expect(step.isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider))
        #expect(!step.shouldSkip(dataManager: dataManager, timeProvider: timeProvider))
        
        // Test button text using compass check manager
        let compassCheckManager = appComponents.compassCheckManager
        // Set to plan step for testing
        compassCheckManager.state = .inProgress(PlanStep())
        #expect(compassCheckManager.moveStateForwardText == "Finish")
        
        // act should not change task states
        let initialTaskCount = dataManager.items.count
        step.act(dataManager: dataManager, timeProvider: timeProvider, preferences: appComponents.preferences)
        #expect(dataManager.items.count == initialTaskCount)
    }
    
    // MARK: - Step Enablement Tests
    
    @Test
    func testStepEnablementSystem() throws {
        let testPreferences = CloudPreferences(store: TestPreferences(), timeProvider: RealTimeProvider())
        
        // Test default states
        let informDefault = testPreferences.isCompassCheckStepEnabled(stepId: "inform")
        let planDefault = testPreferences.isCompassCheckStepEnabled(stepId: "plan")
        print("DEBUG: Default states - inform: \(informDefault), plan: \(planDefault)")
        
        #expect(informDefault == true)
        #expect(planDefault == false) // Disabled by default
        
        // Test enabling a step
        testPreferences.setCompassCheckStepEnabled(stepId: "plan", enabled: true)
        let planAfterEnable = testPreferences.isCompassCheckStepEnabled(stepId: "plan")
        print("DEBUG: Plan after enable: \(planAfterEnable)")
        #expect(planAfterEnable == true)
        
        // Test disabling a step
        testPreferences.setCompassCheckStepEnabled(stepId: "inform", enabled: false)
        let informAfterDisable = testPreferences.isCompassCheckStepEnabled(stepId: "inform")
        print("DEBUG: Inform after disable: \(informAfterDisable)")
        #expect(informAfterDisable == false)
        
        // Test re-enabling
        testPreferences.setCompassCheckStepEnabled(stepId: "inform", enabled: true)
        let informAfterReEnable = testPreferences.isCompassCheckStepEnabled(stepId: "inform")
        print("DEBUG: Inform after re-enable: \(informAfterReEnable)")
        #expect(informAfterReEnable == true)
    }
    
    @Test
    func testCalendarAccessWithPlanStepDisabled() throws {
        // Test that calendar access is not requested when plan step is disabled
        let calendarManager = CalendarManager()
        let planStepEnabled = false
        
        // Calendar access should not be requested when plan step is disabled
        #expect(calendarManager.shouldRequestCalendarAccess(planStepEnabled: planStepEnabled) == false)
        
        // Test with plan step enabled
        let planStepEnabledTrue = true
        #expect(calendarManager.shouldRequestCalendarAccess(planStepEnabled: planStepEnabledTrue) == true)
    }
    
    // MARK: - Step Manager Tests
    
    @Test
    func testStepManagerFlow() throws {
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader(), preferences: createTestPreferencesWithPlanEnabled())
        let compassCheckManager = appComponents.compassCheckManager
        
        // Test getting current step - we now work directly with step instances
        let informStep = InformStep()
        #expect(informStep.id == "inform")
        
        // Test step progression through moveStateForward
        #expect(compassCheckManager.currentStep.id == "inform")
        
        // Should move from inform to currentPriorities (because we have priority tasks)
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        
        // Should move from currentPriorities to pending (because we have pending tasks)
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "pending")
        
        // Should move from pending to dueDate (because we have due tasks)
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "dueDate")
        
        // Should move from dueDate to review
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "review")
        
        // Should move from review to plan (on macOS)
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "plan")
        
        // Should finish at plan (end of flow)
        compassCheckManager.moveStateForward()
        // The compass check should be ended, so we can't test the step directly
    }
    
    @Test
    func testStepManagerFlowWithEmptyData() throws {
        // Create steps with controlled skipping behavior for predictable testing
        let stepsWithControlledSkipping: [any CompassCheckStep] = [
            InformStep(),
            CurrentPrioritiesStep(), // Will be skipped (no priority tasks)
            PendingResponsesStep(),  // Will be skipped (no pending tasks)
            DueDateStep(),           // Will be skipped (no due tasks)
            ReviewStep(),
            PlanStep()
        ]
        let appComponents = setupApp(isTesting: true, loader: createEmptyDataLoader(), preferences: createTestPreferencesWithPlanEnabled(), compassCheckSteps: stepsWithControlledSkipping)
        let compassCheckManager = appComponents.compassCheckManager
        
        // With no tasks, should skip directly from inform to review
        #expect(compassCheckManager.currentStep.id == "inform")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "review")
        
        // Should move from review to plan (on macOS)
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "plan")
        
        // Test that skipped steps show correct button text
        // Reset to inform step for testing button text
        compassCheckManager.state = .inProgress(InformStep())
        #expect(compassCheckManager.moveStateForwardText == "Next")
        
        // Test review step button text
        compassCheckManager.state = .inProgress(ReviewStep())
        #expect(compassCheckManager.moveStateForwardText == "Next")
        
        // Test plan step button text
        compassCheckManager.state = .inProgress(PlanStep())
        #expect(compassCheckManager.moveStateForwardText == "Finish")
    }
    
    @Test
    func testStepManagerFlowWithOnlyPriorityTasks() throws {
        // Create a focused step configuration that tests priority task handling
        let priorityFocusedSteps: [any CompassCheckStep] = [
            InformStep(),
            CurrentPrioritiesStep(), // Should be included (has priority tasks)
            PendingResponsesStep(),  // Should be skipped (no pending tasks)
            DueDateStep(),           // Should be skipped (no due tasks)
            ReviewStep()
        ]
        let appComponents = setupApp(isTesting: true, loader: createPriorityOnlyDataLoader(), compassCheckSteps: priorityFocusedSteps)
        let compassCheckManager = appComponents.compassCheckManager
        
        // Should move from inform to currentPriorities
        #expect(compassCheckManager.currentStep.id == "inform")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        
        // Should skip pending and dueDate, go directly to review
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "review")
        
        // Test button text reflects the focused flow
        // Reset to test button text
        compassCheckManager.state = .inProgress(InformStep())
        #expect(compassCheckManager.moveStateForwardText == "Next")
        
        compassCheckManager.state = .inProgress(CurrentPrioritiesStep())
        #expect(compassCheckManager.moveStateForwardText == "Next")
        
        compassCheckManager.state = .inProgress(ReviewStep())
        #expect(compassCheckManager.moveStateForwardText == "Finish")
    }
    
    @Test
    func testStepManagerMoveToNextStep() throws {
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader())
        let compassCheckManager = appComponents.compassCheckManager
        let dataManager = appComponents.dataManager
        
        // Test moving from inform to next step
        #expect(compassCheckManager.currentStep.id == "inform")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        
        // Priority tasks should still be there (InformStep.act does nothing)
        let priorityTasks = dataManager.list(which: .priority)
        #expect(priorityTasks.count > 0) // Should still have priority tasks
        
        // Test moving from currentPriorities to next step
        // This should execute CurrentPrioritiesStep.act (moves priorities to open)
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "pending")
        
        // Now verify that priority tasks were moved to open
        let priorityTasksAfter = dataManager.list(which: .priority)
        #expect(priorityTasksAfter.count == 0) // Should be empty now
    }
    
    @Test
    func testStepManagerButtonText() throws {
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader(), preferences: createTestPreferencesWithPlanEnabled())
        let compassCheckManager = appComponents.compassCheckManager
        
        // Test button text for different states
        #expect(compassCheckManager.moveStateForwardText == "Next") // Should be "Next" for inform step
        
        // Test currentPriorities step
        compassCheckManager.state = .inProgress(CurrentPrioritiesStep())
        #expect(compassCheckManager.moveStateForwardText == "Next")
        
        // Test review step
        compassCheckManager.state = .inProgress(ReviewStep())
        #expect(compassCheckManager.moveStateForwardText == "Next") // Should be "Next" on macOS
        
        // Test plan step
        compassCheckManager.state = .inProgress(PlanStep())
        #expect(compassCheckManager.moveStateForwardText == "Finish")
    }
    
    // MARK: - Integration Tests
    
    @Test
    func testCompleteCompassCheckFlow() throws {
        // Create a simplified, predictable step flow for testing
        let simplifiedSteps: [any CompassCheckStep] = [
            InformStep(),
            CurrentPrioritiesStep(),
            ReviewStep(),
            PlanStep()
        ]
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader(), preferences: createTestPreferencesWithPlanEnabled(), compassCheckSteps: simplifiedSteps)
        let compassCheckManager = appComponents.compassCheckManager
        let dataManager = appComponents.dataManager
        
        // Track initial state
        let initialPriorityCount = dataManager.list(which: .priority).count
        let initialPendingCount = dataManager.list(which: .pendingResponse).count
        let initialOpenCount = dataManager.list(which: .open).count
        
        // Simulate complete flow with predictable steps
        var currentStep: any CompassCheckStep = InformStep()
        var stepCount = 0
        let expectedStepIds = ["inform", "currentPriorities", "review", "plan"]
        
        for expectedId in expectedStepIds {
            #expect(currentStep.id == expectedId)
            
            if currentStep.id == "plan" {
                // Final step - should show "Finish"
                compassCheckManager.state = .inProgress(currentStep)
                let buttonText = compassCheckManager.moveStateForwardText
                #expect(buttonText == "Finish")
                break
            }
            
            // Move to next step
            compassCheckManager.state = .inProgress(currentStep)
            compassCheckManager.moveStateForward()
            currentStep = compassCheckManager.currentStep
            stepCount += 1
        }
        
        // Verify we completed the flow
        #expect(currentStep.id == "plan")
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
        // Create a focused step configuration for testing integration
        let focusedSteps: [any CompassCheckStep] = [
            InformStep(),
            CurrentPrioritiesStep(),
            ReviewStep()
        ]
        
        // Use setupApp with custom steps for consistent app component setup
        let appComponents = setupApp(isTesting: true, compassCheckSteps: focusedSteps)
        let compassCheckManager = appComponents.compassCheckManager
        let dataManager = appComponents.dataManager
        
        // Test that the manager uses the step-based system
        #expect(compassCheckManager.currentStep.id == "inform")
        
        // Test moveStateForward to CurrentPrioritiesStep
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        
        // Priority tasks should still exist at this point (not moved yet)
        let priorityTasksBefore = dataManager.list(which: .priority)
        #expect(priorityTasksBefore.count == 1)
        
        // Test moveStateForward from CurrentPrioritiesStep (this should move priority tasks to open)
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "review")
        
        // Now priority tasks should be moved to open
        let priorityTasksAfter = dataManager.list(which: .priority)
        #expect(priorityTasksAfter.count == 0)
        
        // Test button text - should be "Finish" since ReviewStep is the last step
        let buttonText = compassCheckManager.moveStateForwardText
        #expect(buttonText == "Finish")
        
        // Test final step - calling moveStateForward() should complete the compass check
        compassCheckManager.moveStateForward()
        // After completion, the compass check should restart at the first step
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(compassCheckManager.moveStateForwardText == "Next")
    }
    
    // MARK: - Edge Cases and Error Conditions
    
    @Test
    func testStepManagerWithInvalidState() throws {
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader())
        let compassCheckManager = appComponents.compassCheckManager
        
        // Test with valid step (should work)
        let validStep = InformStep()
        #expect(validStep.id == "inform")
        
        // Test button text for valid step
        compassCheckManager.state = .inProgress(validStep)
        let buttonText = compassCheckManager.moveStateForwardText
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
        
        let compassCheckManager = CompassCheckManager(
            dataManager: dataManager,
            uiState: appComponents.uiState,
            preferences: appComponents.preferences,
            timeProvider: appComponents.timeProvider,
            pushNotificationManager: appComponents.pushNotificationManager
        )
        
        // Should skip directly to review
        #expect(compassCheckManager.currentStep.id == "inform")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "review")
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
        
        let compassCheckManager = CompassCheckManager(
            dataManager: dataManager,
            uiState: appComponents.uiState,
            preferences: appComponents.preferences,
            timeProvider: appComponents.timeProvider,
            pushNotificationManager: appComponents.pushNotificationManager
        )
        
        // Should skip dueDate step
        #expect(compassCheckManager.currentStep.id == "inform")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "review")
    }
    
    // MARK: - Platform-Specific Tests
    
    @Test
    func testIOSFlow() throws {
        // Create a custom PlanStep that simulates iOS behavior (always skips)
        struct iOSPlanStep: CompassCheckStep {
            let id: String = "plan"
            let name: String = "iOS Plan Step"
            
            func isPreconditionFulfilled(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
                return false // Always skip on iOS
            }
            
            @ViewBuilder
            func view(compassCheckManager: CompassCheckManager) -> AnyView {
                AnyView(Text("iOS Plan Step"))
            }
            
            func act(dataManager: DataManager, timeProvider: TimeProvider, preferences: CloudPreferences) {
                // No actions needed
            }
        }
        
        // Create platform-specific step configuration for iOS testing
        let iOSSteps: [any CompassCheckStep] = [
            InformStep(),
            CurrentPrioritiesStep(),
            PendingResponsesStep(),
            DueDateStep(),
            ReviewStep(),
            iOSPlanStep() // This should be skipped on iOS
        ]
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader(), compassCheckSteps: iOSSteps)
        let compassCheckManager = appComponents.compassCheckManager
        
        // Test the actual iOS flow - should skip PlanStep
        #expect(compassCheckManager.currentStep.id == "inform")
        
        // Move through the flow step by step, tracking which steps we visit
        var visitedSteps: [String] = []
        visitedSteps.append(compassCheckManager.currentStep.id)
        
        // Navigate through all steps until we reach the end
        while compassCheckManager.moveStateForwardText != "Finish" {
            compassCheckManager.moveStateForward()
            visitedSteps.append(compassCheckManager.currentStep.id)
        }
        
        // On iOS, should end at review step (plan step should be skipped)
        #expect(compassCheckManager.currentStep.id == "review")
        #expect(compassCheckManager.moveStateForwardText == "Finish")
        
        // Verify that PlanStep was skipped (not in visited steps)
        #expect(!visitedSteps.contains("plan"))
        
        // Verify that we visited the expected steps (in some order)
        #expect(visitedSteps.contains("inform"))
        #expect(visitedSteps.contains("currentPriorities"))
        #expect(visitedSteps.contains("pending"))
        #expect(visitedSteps.contains("dueDate"))
        #expect(visitedSteps.contains("review"))
        
        // Test that plan step is properly skipped by verifying it's not in the flow
        // If we try to manually set it to PlanStep, it should be skipped
        compassCheckManager.state = .inProgress(PlanStep())
        // The step should be skipped, so moveStateForward should go to the end
        compassCheckManager.moveStateForward()
        // Should end the compass check since PlanStep was skipped
    }
    
    @Test
    func testMacOSFlow() throws {
        // Create platform-specific step configuration for macOS testing
        let macOSSteps: [any CompassCheckStep] = [
            InformStep(),
            CurrentPrioritiesStep(),
            PendingResponsesStep(),
            DueDateStep(),
            ReviewStep(),
            PlanStep() // This should be included on macOS
        ]
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader(), preferences: createTestPreferencesWithPlanEnabled(), compassCheckSteps: macOSSteps)
        let compassCheckManager = appComponents.compassCheckManager
        
        // Test the actual macOS flow - should include PlanStep
        #expect(compassCheckManager.currentStep.id == "inform")
        
        // Move through the flow step by step, tracking which steps we visit
        var visitedSteps: [String] = []
        visitedSteps.append(compassCheckManager.currentStep.id)
        
        // Navigate through all steps until we reach the end
        while compassCheckManager.moveStateForwardText != "Finish" {
            compassCheckManager.moveStateForward()
            visitedSteps.append(compassCheckManager.currentStep.id)
        }
        
        // On macOS, should end at plan step
        #expect(compassCheckManager.currentStep.id == "plan")
        #expect(compassCheckManager.moveStateForwardText == "Finish")
        
        // Verify that PlanStep was included (in visited steps)
        #expect(visitedSteps.contains("plan"))
        
        // Verify that we visited the expected steps (in some order)
        #expect(visitedSteps.contains("inform"))
        #expect(visitedSteps.contains("currentPriorities"))
        #expect(visitedSteps.contains("pending"))
        #expect(visitedSteps.contains("dueDate"))
        #expect(visitedSteps.contains("review"))
        #expect(visitedSteps.contains("plan"))
    }
    
    // MARK: - MoveToGraveyardStep Tests
    
    @Test
    func testMoveToGraveyardStep() throws {
        let testPreferences = CloudPreferences(store: TestPreferences(), timeProvider: RealTimeProvider())
        let testDataLoader = createTestDataLoader()
        let appComponents = setupApp(isTesting: true, loader: testDataLoader, preferences: testPreferences)
        let dataManager = appComponents.dataManager
        let timeProvider = appComponents.timeProvider
        
        // Create some old tasks that should be moved to graveyard
        let oldTask1 = dataManager.addAndFindItem(
            title: "Old task 1",
            changedDate: timeProvider.getDate(daysPrior: 35), // 35 days old
            state: .open
        )
        let oldTask2 = dataManager.addAndFindItem(
            title: "Old task 2", 
            changedDate: timeProvider.getDate(daysPrior: 40), // 40 days old
            state: .priority
        )
        let recentTask = dataManager.addAndFindItem(
            title: "Recent task",
            changedDate: timeProvider.getDate(daysPrior: 5), // 5 days old
            state: .open
        )
        
        // Verify initial state
        #expect(dataManager.list(which: .open).contains { $0.id == oldTask1.id })
        #expect(dataManager.list(which: .priority).contains { $0.id == oldTask2.id })
        #expect(dataManager.list(which: .open).contains { $0.id == recentTask.id })
        #expect(dataManager.list(which: .dead).isEmpty)
        
        // Test the MoveToGraveyardStep
        let graveyardStep = MoveToGraveyardStep()
        
        // Verify step properties
        #expect(graveyardStep.id == "moveToGraveyard")
        #expect(graveyardStep.name == "Move unused Tasks to Graveyard")
        #expect(graveyardStep.isSilent == true)
        #expect(graveyardStep.isPreconditionFulfilled(dataManager: dataManager, timeProvider: timeProvider) == true)
        
        // Execute the step
        graveyardStep.act(dataManager: dataManager, timeProvider: timeProvider, preferences: testPreferences)
        
        // Verify that old tasks were moved to graveyard
        #expect(!dataManager.list(which: .open).contains { $0.id == oldTask1.id })
        #expect(!dataManager.list(which: .priority).contains { $0.id == oldTask2.id })
        #expect(dataManager.list(which: .dead).contains { $0.id == oldTask1.id })
        #expect(dataManager.list(which: .dead).contains { $0.id == oldTask2.id })
        
        // Verify that recent task was not moved
        #expect(dataManager.list(which: .open).contains { $0.id == recentTask.id })
    }
    
    @Test
    func testMoveToGraveyardStepWithCustomExpiry() throws {
        let testPreferences = CloudPreferences(store: TestPreferences(), timeProvider: RealTimeProvider())
        // Set custom expiry to 10 days
        testPreferences.expiryAfter = 10
        
        let testDataLoader = createTestDataLoader()
        let appComponents = setupApp(isTesting: true, loader: testDataLoader, preferences: testPreferences)
        let dataManager = appComponents.dataManager
        let timeProvider = appComponents.timeProvider
        
        // Create tasks with different ages
        let veryOldTask = dataManager.addAndFindItem(
            title: "Very old task",
            changedDate: timeProvider.getDate(daysPrior: 15), // 15 days old
            state: .open
        )
        let moderatelyOldTask = dataManager.addAndFindItem(
            title: "Moderately old task",
            changedDate: timeProvider.getDate(daysPrior: 8), // 8 days old
            state: .open
        )
        let recentTask = dataManager.addAndFindItem(
            title: "Recent task",
            changedDate: timeProvider.getDate(daysPrior: 3), // 3 days old
            state: .open
        )
        
        // Execute the step
        let graveyardStep = MoveToGraveyardStep()
        graveyardStep.act(dataManager: dataManager, timeProvider: timeProvider, preferences: testPreferences)
        
        // Verify that only the very old task (15 days) was moved to graveyard
        #expect(!dataManager.list(which: .open).contains { $0.id == veryOldTask.id })
        #expect(dataManager.list(which: .dead).contains { $0.id == veryOldTask.id })
        
        // Verify that moderately old and recent tasks were not moved
        #expect(dataManager.list(which: .open).contains { $0.id == moderatelyOldTask.id })
        #expect(dataManager.list(which: .open).contains { $0.id == recentTask.id })
    }
    
    @Test
    func testMoveToGraveyardStepInCompassCheckFlow() throws {
        // Create a focused step configuration for testing integration
        let focusedSteps: [any CompassCheckStep] = [
            InformStep(),
            MoveToGraveyardStep()  // Only include the graveyard step
        ]
        
        let testPreferences = CloudPreferences(store: TestPreferences(), timeProvider: RealTimeProvider())
        let testDataLoader = createTestDataLoader()
        let appComponents = setupApp(isTesting: true, loader: testDataLoader, preferences: testPreferences, compassCheckSteps: focusedSteps)
        let timeProvider = appComponents.timeProvider
        
        let compassCheckManager = appComponents.compassCheckManager
        let dataManager = appComponents.dataManager
        
        // Create some old tasks
        let oldTask = dataManager.addAndFindItem(
            title: "Old task",
            changedDate: timeProvider.getDate(daysPrior: 35),
            state: .open
        )
        
        // Verify initial state
        #expect(dataManager.list(which: .open).contains { $0.id == oldTask.id })
        #expect(dataManager.list(which: .dead).isEmpty)
        
        // Start compass check and go through the flow
        compassCheckManager.startCompassCheckNow()
        
        // Should start at InformStep
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(compassCheckManager.moveStateForwardText == "Finish")
        
        // Move forward - should execute InformStep and then MoveToGraveyardStep automatically
        compassCheckManager.moveStateForward()
        
        // Should be finished now
        #expect(compassCheckManager.isFinished, "Compass check should be finished")
        
        // The MoveToGraveyardStep should have been executed automatically as a silent step
        // Refresh data to ensure we see the latest state
        dataManager.callFetch()
        
        // Verify that the old task was moved to graveyard
        #expect(!dataManager.list(which: .open).contains { $0.id == oldTask.id })
        #expect(dataManager.list(which: .dead).contains { $0.id == oldTask.id })
    }
    
    @Test
    func testMoveToGraveyardStepCanBeDisabled() throws {
        let testPreferences = CloudPreferences(store: TestPreferences(), timeProvider: RealTimeProvider())
        // Disable the moveToGraveyard step
        testPreferences.setCompassCheckStepEnabled(stepId: "moveToGraveyard", enabled: false)
        
        let testDataLoader = createTestDataLoader()
        let appComponents = setupApp(isTesting: true, loader: testDataLoader, preferences: testPreferences)
        let dataManager = appComponents.dataManager
        let timeProvider = appComponents.timeProvider
        
        // Create an old task
        let oldTask = dataManager.addAndFindItem(
            title: "Old task",
            changedDate: timeProvider.getDate(daysPrior: 35),
            state: .open
        )
        
        // Verify initial state
        #expect(dataManager.list(which: .open).contains { $0.id == oldTask.id })
        #expect(dataManager.list(which: .dead).isEmpty)
        
        // Start compass check and go through the flow
        let compassCheckManager = appComponents.compassCheckManager
        compassCheckManager.startCompassCheckNow()
        
        // Navigate through all steps until we reach the end
        while compassCheckManager.moveStateForwardText != "Finish" {
            compassCheckManager.moveStateForward()
        }
        
        // The MoveToGraveyardStep should have been skipped because it's disabled
        // Verify that the old task was NOT moved to graveyard
        #expect(dataManager.list(which: .open).contains { $0.id == oldTask.id })
        #expect(dataManager.list(which: .dead).isEmpty)
    }
    
    // MARK: - Comprehensive Silent Step Tests
    
    @Test
    func testSilentStepExecution() throws {
        // Test that silent steps are executed automatically
        let testPreferences = CloudPreferences(store: TestPreferences(), timeProvider: RealTimeProvider())
        let testDataLoader = createTestDataLoader()
        let appComponents = setupApp(isTesting: true, loader: testDataLoader, preferences: testPreferences)
        let dataManager = appComponents.dataManager
        let timeProvider = appComponents.timeProvider
        
        // Create an old task
        let oldTask = dataManager.addAndFindItem(
            title: "Old task",
            changedDate: timeProvider.getDate(daysPrior: 35),
            state: .open
        )
        
        // Verify initial state
        #expect(dataManager.list(which: .open).contains { $0.id == oldTask.id })
        #expect(dataManager.list(which: .dead).isEmpty)
        
        // Test the MoveToGraveyardStep directly
        let graveyardStep = MoveToGraveyardStep()
        #expect(graveyardStep.isSilent == true)
        
        // Execute the step
        graveyardStep.act(dataManager: dataManager, timeProvider: timeProvider, preferences: testPreferences)
        
        // Verify the task was moved to graveyard
        #expect(!dataManager.list(which: .open).contains { $0.id == oldTask.id })
        #expect(dataManager.list(which: .dead).contains { $0.id == oldTask.id })
    }
    
    @Test
    func testSilentStepInFlow() throws {
        // Test silent step execution in a flow with only silent steps
        let focusedSteps: [any CompassCheckStep] = [
            InformStep(),
            MoveToGraveyardStep()
        ]
        
        let testPreferences = CloudPreferences(store: TestPreferences(), timeProvider: RealTimeProvider())
        let testDataLoader = createTestDataLoader()
        let appComponents = setupApp(isTesting: true, loader: testDataLoader, preferences: testPreferences, compassCheckSteps: focusedSteps)
        let timeProvider = appComponents.timeProvider
        
        let compassCheckManager = appComponents.compassCheckManager
        let dataManager = appComponents.dataManager
        
        // Create an old task
        let oldTask = dataManager.addAndFindItem(
            title: "Old task",
            changedDate: timeProvider.getDate(daysPrior: 35),
            state: .open
        )
        
        // Verify initial state
        #expect(dataManager.list(which: .open).contains { $0.id == oldTask.id })
        #expect(dataManager.list(which: .dead).isEmpty)
        
        // Start compass check
        compassCheckManager.startCompassCheckNow()
        
        // Should start at InformStep
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(compassCheckManager.moveStateForwardText == "Finish")
        
        // Move forward - should execute InformStep and then MoveToGraveyardStep automatically
        compassCheckManager.moveStateForward()
        
        // Should be at the end now
        #expect(compassCheckManager.currentStep.id == "inform") // Should restart
        #expect(compassCheckManager.moveStateForwardText == "Finish")
        
        // Refresh data to ensure we see the latest state
        dataManager.callFetch()
        
        // Verify the task was moved to graveyard
        #expect(!dataManager.list(which: .open).contains { $0.id == oldTask.id })
        #expect(dataManager.list(which: .dead).contains { $0.id == oldTask.id })
    }
    
    @Test
    func testMoveStateForwardOnLastStep() throws {
        // Test what happens when we call moveStateForward on the last step
        let focusedSteps: [any CompassCheckStep] = [
            InformStep(),
            MoveToGraveyardStep()  // Only include the graveyard step
        ]
        
        let testPreferences = CloudPreferences(store: TestPreferences(), timeProvider: RealTimeProvider())
        let testDataLoader = createTestDataLoader()
        let appComponents = setupApp(isTesting: true, loader: testDataLoader, preferences: testPreferences, compassCheckSteps: focusedSteps)
        let timeProvider = appComponents.timeProvider
        
        let compassCheckManager = appComponents.compassCheckManager
        let dataManager = appComponents.dataManager
        
        // Create an old task
        let oldTask = dataManager.addAndFindItem(
            title: "Old task",
            changedDate: timeProvider.getDate(daysPrior: 35),
            state: .open
        )
        
        // Start compass check
        compassCheckManager.startCompassCheckNow()
        
        // Should start at InformStep
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(compassCheckManager.moveStateForwardText == "Finish")
        #expect(!compassCheckManager.isFinished, "Should not be finished at first step")
        
        // Move forward - should execute InformStep and then MoveToGraveyardStep automatically
        compassCheckManager.moveStateForward()
        
        // After moveStateForward on last step, should be back at first step
        #expect(compassCheckManager.currentStep.id == "inform", "Should be back at first step")
        #expect(compassCheckManager.moveStateForwardText == "Finish", "Button should show Finish")
        #expect(compassCheckManager.isFinished, "Should be finished after moving after all (active) steps")
        
        // Refresh data to ensure we see the latest state
        dataManager.callFetch()
        
        // Verify the task was moved to graveyard
        #expect(!dataManager.list(which: .open).contains { $0.id == oldTask.id })
        #expect(dataManager.list(which: .dead).contains { $0.id == oldTask.id })
    }
    
    @Test
    func testButtonTextWithSilentSteps() throws {
        // Test button text logic with silent steps
        let focusedSteps: [any CompassCheckStep] = [
            InformStep(),
            MoveToGraveyardStep(), // Silent step
            ReviewStep()
        ]
        
        let appComponents = setupApp(isTesting: true, compassCheckSteps: focusedSteps)
        let compassCheckManager = appComponents.compassCheckManager
        
        // Should start at InformStep
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(compassCheckManager.moveStateForwardText == "Next") // Next visible step is ReviewStep
        
        // Move forward - should execute InformStep and MoveToGraveyardStep automatically
        compassCheckManager.moveStateForward()
        
        // Should be at ReviewStep now
        #expect(compassCheckManager.currentStep.id == "review")
        #expect(compassCheckManager.moveStateForwardText == "Finish") // ReviewStep is the last step
    }
    
    @Test
    func testMultipleSilentSteps() throws {
        // Test multiple consecutive silent steps
        struct SilentStep1: CompassCheckStep {
            let id: String = "silent1"
            let name: String = "Silent Step 1"
            let isSilent: Bool = true
            
            func isPreconditionFulfilled(dataManager: DataManager, timeProvider: TimeProvider) -> Bool { true }
            
            @ViewBuilder
            func view(compassCheckManager: CompassCheckManager) -> AnyView {
                AnyView(Text("Silent 1"))
            }
            
            func act(dataManager: DataManager, timeProvider: TimeProvider, preferences: CloudPreferences) {
                debugPrint("Executing SilentStep1")
            }
        }
        
        struct SilentStep2: CompassCheckStep {
            let id: String = "silent2"
            let name: String = "Silent Step 2"
            let isSilent: Bool = true
            
            func isPreconditionFulfilled(dataManager: DataManager, timeProvider: TimeProvider) -> Bool { true }
            
            @ViewBuilder
            func view(compassCheckManager: CompassCheckManager) -> AnyView {
                AnyView(Text("Silent 2"))
            }
            
            func act(dataManager: DataManager, timeProvider: TimeProvider, preferences: CloudPreferences) {
                debugPrint("Executing SilentStep2")
            }
        }
        
        let focusedSteps: [any CompassCheckStep] = [
            InformStep(),
            SilentStep1(),
            SilentStep2(),
            ReviewStep()
        ]
        
        let appComponents = setupApp(isTesting: true, compassCheckSteps: focusedSteps)
        let compassCheckManager = appComponents.compassCheckManager
        
        // Should start at InformStep
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(compassCheckManager.moveStateForwardText == "Next")
        
        // Move forward - should execute all steps automatically
        compassCheckManager.moveStateForward()
        
        // Should be at ReviewStep now
        #expect(compassCheckManager.currentStep.id == "review")
        #expect(compassCheckManager.moveStateForwardText == "Finish")
    }
}
