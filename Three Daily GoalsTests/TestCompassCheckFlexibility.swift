//
//  TestCompassCheckFlexibility.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import Testing
import Foundation
import SwiftUI

@testable import Three_Daily_Goals
@testable import tdgCoreMain

@MainActor
/// Tests demonstrating the flexibility of the new dependency injection approach
struct TestCompassCheckFlexibility {
    
    /// Helper function to create test preferences with plan step enabled
    private func createTestPreferencesWithPlanEnabled() -> CloudPreferences {
        let testPreferences = CloudPreferences(store: TestPreferences(), timeProvider: RealTimeProvider())
        testPreferences.setCompassCheckStepEnabled(stepId: "plan", enabled: true)
        return testPreferences
    }
    
    // MARK: - Test Helpers
    
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
    
    
    // MARK: - Custom Step for Testing
    
    /// A custom step that always shows "Custom" button text for testing
    struct CustomTestStep: CompassCheckStep {
        let id: String = "customTest"
        let name: String = "Custom Test Step"
        
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
        let id: String = "alwaysSkip"
        let name: String = "Always Skip Step"
        
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
        // Create a custom compass check manager with only our test step
        let customSteps: [any CompassCheckStep] = [CustomTestStep()]
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader(), compassCheckSteps: customSteps)
        let compassCheckManager = appComponents.compassCheckManager
        
        // Verify the custom step is available
        #expect(compassCheckManager.currentStep.id == "customTest")
        #expect(compassCheckManager.currentStep is CustomTestStep)
        
        // Test that the custom step manager works correctly
        // Since it's the only step, moving forward should stay on the same step
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "customTest")
    }
    
    @Test
    func testStepSkippingBehavior() throws {
        // Create a compass check manager with a step that always skips itself
        let stepsWithSkip: [any CompassCheckStep] = [
            InformStep(),
            AlwaysSkipStep(), // This should always be skipped
            ReviewStep()
        ]
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader(), compassCheckSteps: stepsWithSkip)
        let compassCheckManager = appComponents.compassCheckManager
        
        // Test that the skipping step is properly skipped
        #expect(compassCheckManager.currentStep.id == "inform")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "review") // Should skip "alwaysSkip" and go to "review"
        
        // Test button text reflects the skipping behavior
        #expect(compassCheckManager.moveStateForwardText == "Finish") // Should show "Finish" for review
    }
    
    @Test
    func testCompassCheckManagerWithCustomSteps() throws {
        // Create a custom compass check manager with minimal steps
        let customSteps: [any CompassCheckStep] = [InformStep(), ReviewStep()]
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader(), compassCheckSteps: customSteps)
        let compassCheckManager = appComponents.compassCheckManager
        
        // Test that the CompassCheckManager uses our custom steps
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(compassCheckManager.moveStateForwardText == "Next") // Should show "Next" for inform
        
        // Move to next step
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "review") // Should go directly to review (skipping other steps)
        
        // Test button text for the final step
        #expect(compassCheckManager.moveStateForwardText == "Finish") // Should show "Finish" for review
    }
    
    @Test
    func testMinimalStepConfiguration() throws {
        // Create a minimal step configuration with just inform and review
        let minimalSteps: [any CompassCheckStep] = [
            InformStep(),
            ReviewStep()
        ]
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader(), compassCheckSteps: minimalSteps)
        let compassCheckManager = appComponents.compassCheckManager
        
        // Test the minimal flow
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(compassCheckManager.moveStateForwardText == "Next")
        
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "review")
        #expect(compassCheckManager.moveStateForwardText == "Finish")
        
        // Test that we only have the expected steps
        #expect(compassCheckManager.currentStep.id == "review")
    }
    
    @Test
    func testStepOrderingFlexibility() throws {
        // Create steps in a different order
        let reorderedSteps: [any CompassCheckStep] = [
            ReviewStep(),    // Start with review
            InformStep(),    // Then inform
            PlanStep()       // End with plan
        ]
        let appComponents = setupApp(isTesting: true, loader: createTestDataLoader(), preferences: createTestPreferencesWithPlanEnabled(), compassCheckSteps: reorderedSteps)
        let compassCheckManager = appComponents.compassCheckManager
        
        // Test the reordered flow - should start with the first step (review)
        #expect(compassCheckManager.currentStep.id == "review")
        #expect(compassCheckManager.moveStateForwardText == "Next")
        
        // Move to next step (inform)
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(compassCheckManager.moveStateForwardText == "Next")
        
        // Move to next step (plan)
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "plan")
        #expect(compassCheckManager.moveStateForwardText == "Finish")
    }
}
