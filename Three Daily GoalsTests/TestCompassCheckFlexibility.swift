//
//  TestCompassCheckFlexibility.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Testing
import Foundation

@testable import Three_Daily_Goals

/// Tests demonstrating the flexibility of the new dependency injection approach
struct TestCompassCheckFlexibility {
    
    // MARK: - Test Helpers
    
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
    
    // MARK: - Custom Step for Testing
    
    /// A custom step that always shows "Custom" button text for testing
    struct CustomTestStep: CompassCheckStep {
        let state: CompassCheckState = .inform
        
        func isPreconditionFulfilled(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
            return true
        }
        
        @ViewBuilder
        func view(compassCheckManager: CompassCheckManager) -> AnyView {
            AnyView(Text("Custom Test Step"))
        }
        
        func onMoveToNext(dataManager: DataManager, timeProvider: TimeProvider) {
            // Custom action for testing
        }
    }
    
    /// A step that always skips itself for testing edge cases
    struct AlwaysSkipStep: CompassCheckStep {
        let state: CompassCheckState = .currentPriorities
        
        func isPreconditionFulfilled(dataManager: DataManager, timeProvider: TimeProvider) -> Bool {
            return false // Always skip this step
        }
        
        @ViewBuilder
        func view(compassCheckManager: CompassCheckManager) -> AnyView {
            AnyView(Text("This should never be shown"))
        }
        
        func onMoveToNext(dataManager: DataManager, timeProvider: TimeProvider) {
            // This should never be called
        }
    }
    
    // MARK: - Tests
    
    @Test
    func testCustomStepInjection() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        
        // Create a custom step manager with only our test step
        let customSteps: [CompassCheckStep] = [CustomTestStep()]
        let customStepManager = CompassCheckStepManager(
            dataManager: dataManager, 
            timeProvider: timeProvider, 
            steps: customSteps
        )
        
        // Verify the custom step is available
        let customStep = customStepManager.getCurrentStep(for: .inform)
        #expect(customStep != nil)
        #expect(customStep is CustomTestStep)
        
        // Test that the custom step manager works correctly
        let nextState = customStepManager.getNextStep(from: .inform, os: .macOS)
        #expect(nextState == .inform) // Should be the last step since it's the only one
    }
    
    @Test
    func testStepSkippingBehavior() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        
        // Create a step manager with a step that always skips itself
        let stepsWithSkip: [CompassCheckStep] = [
            InformStep(),
            AlwaysSkipStep(), // This should always be skipped
            ReviewStep()
        ]
        let stepManager = CompassCheckStepManager(
            dataManager: dataManager, 
            timeProvider: timeProvider, 
            steps: stepsWithSkip
        )
        
        // Test that the skipping step is properly skipped
        let nextFromInform = stepManager.getNextStep(from: .inform, os: .macOS)
        #expect(nextFromInform == .review) // Should skip .currentPriorities and go to .review
        
        // Test button text reflects the skipping behavior
        let buttonText = stepManager.getButtonText(for: .inform, os: .macOS)
        #expect(buttonText == "Next") // Should show "Next" because .review is available
    }
    
    @Test
    func testCompassCheckManagerWithCustomStepManager() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        let uiState = UIStateManager()
        let preferences = CloudPreferences()
        let pushNotificationManager = PushNotificationManager()
        
        // Create a custom step manager
        let customSteps: [CompassCheckStep] = [InformStep(), ReviewStep()]
        let customStepManager = CompassCheckStepManager(
            dataManager: dataManager, 
            timeProvider: timeProvider, 
            steps: customSteps
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
        
        // Test that the CompassCheckManager uses our custom step manager
        #expect(compassCheckManager.moveStateForwardText == "Next") // Should show "Next" for .inform
        
        // Move to next step
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state == .review) // Should go directly to review (skipping other steps)
        
        // Test button text for the final step
        #expect(compassCheckManager.moveStateForwardText == "Finish") // Should show "Finish" for .review
    }
    
    @Test
    func testMinimalStepConfiguration() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        
        // Create a minimal step configuration with just inform and review
        let minimalSteps: [CompassCheckStep] = [
            InformStep(),
            ReviewStep()
        ]
        let minimalStepManager = CompassCheckStepManager(
            dataManager: dataManager, 
            timeProvider: timeProvider, 
            steps: minimalSteps
        )
        
        // Test the minimal flow
        #expect(minimalStepManager.getButtonText(for: .inform, os: .macOS) == "Next")
        #expect(minimalStepManager.getButtonText(for: .review, os: .macOS) == "Finish")
        
        // Test that other states are not available
        #expect(minimalStepManager.getCurrentStep(for: .currentPriorities) == nil)
        #expect(minimalStepManager.getCurrentStep(for: .plan) == nil)
    }
    
    @Test
    func testStepOrderingFlexibility() throws {
        let dataManager = createTestDataManager()
        let timeProvider = RealTimeProvider()
        
        // Create steps in a different order
        let reorderedSteps: [CompassCheckStep] = [
            ReviewStep(),    // Start with review
            InformStep(),    // Then inform
            PlanStep()       // End with plan
        ]
        let reorderedStepManager = CompassCheckStepManager(
            dataManager: dataManager, 
            timeProvider: timeProvider, 
            steps: reorderedSteps
        )
        
        // Test the reordered flow
        let nextFromReview = reorderedStepManager.getNextStep(from: .review, os: .macOS)
        #expect(nextFromReview == .inform) // Should go to inform next
        
        let nextFromInform = reorderedStepManager.getNextStep(from: .inform, os: .macOS)
        #expect(nextFromInform == .plan) // Should go to plan next
        
        let nextFromPlan = reorderedStepManager.getNextStep(from: .plan, os: .macOS)
        #expect(nextFromPlan == .plan) // Should be the last step
    }
}
