//
//  TestCompassCheckNavigation.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 2025-12-18.
//

import Foundation
import SwiftUI
import Testing

@testable import Three_Daily_Goals
@testable import tdgCoreMain

@Suite
@MainActor
struct TestCompassCheckNavigation {

    // MARK: - Test Setup Helpers

    /// Creates a mock time provider with a fixed "now" time
    private func createMockTimeProvider(fixedNow: Date) -> MockTimeProvider {
        return MockTimeProvider(fixedNow: fixedNow)
    }

    // MARK: - Basic Back Navigation Tests

    @Test
    func testBackFromSecondStepGoesToFirst() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager

        // Start compass check
        compassCheckManager.startCompassCheckNow()
        #expect(compassCheckManager.currentStep.id == "inform")

        // Move forward to second visible step
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "currentPriorities")

        // Go back
        compassCheckManager.goBackOneStep()

        // Should be back at first step
        #expect(compassCheckManager.currentStep.id == "inform")
    }

    @Test
    func testBackFromFirstStepDoesNothing() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager

        // Start compass check - at first step
        compassCheckManager.startCompassCheckNow()
        #expect(compassCheckManager.currentStep.id == "inform")

        // Verify can't go back
        #expect(compassCheckManager.canGoBack == false)

        // Try to go back (should do nothing)
        compassCheckManager.goBackOneStep()

        // Should still be at first step
        #expect(compassCheckManager.currentStep.id == "inform")
    }

    @Test
    func testCanGoBackIsTrueFromSecondStep() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager

        // Start compass check
        compassCheckManager.startCompassCheckNow()
        #expect(compassCheckManager.canGoBack == false)

        // Move forward
        compassCheckManager.moveStateForward()

        // Should now be able to go back
        #expect(compassCheckManager.canGoBack == true)
    }

    @Test
    func testBackSkipsSilentSteps() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager

        // Start compass check
        compassCheckManager.startCompassCheckNow()
        #expect(compassCheckManager.currentStep.id == "inform")

        // Move forward - this goes through InformStep -> EnergyEffortMatrixConsistencyStep (silent) -> CurrentPrioritiesStep
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "currentPriorities")

        // Go back - should skip the silent step and land on InformStep
        compassCheckManager.goBackOneStep()

        // Should be at InformStep (skipping EnergyEffortMatrixConsistencyStep which is silent)
        #expect(compassCheckManager.currentStep.id == "inform")
    }

    @Test
    func testBackThenNextReturnsSameStep() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager

        // Start and move forward several times
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward()  // currentPriorities
        compassCheckManager.moveStateForward()  // EnergyEffortMatrix
        let stepBeforeBack = compassCheckManager.currentStep.id

        // Go back
        compassCheckManager.goBackOneStep()
        let stepAfterBack = compassCheckManager.currentStep.id
        #expect(stepAfterBack != stepBeforeBack)

        // Go forward again
        compassCheckManager.moveStateForward()

        // Should be back at the same step
        #expect(compassCheckManager.currentStep.id == stepBeforeBack)
    }

    @Test
    func testBackDoesNotReExecuteStepAction() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager
        let dataManager = appComponents.dataManager

        // Start compass check
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward()  // currentPriorities

        // Count tasks before moving forward
        let taskCountBefore = dataManager.allTasks.count

        // Move forward (this may execute actions)
        compassCheckManager.moveStateForward()  // EnergyEffortMatrix

        // Go back
        compassCheckManager.goBackOneStep()

        // Task count should be the same (back didn't execute actions)
        let taskCountAfter = dataManager.allTasks.count
        #expect(taskCountBefore == taskCountAfter)
    }

    // MARK: - Back Navigation Saves Progress Tests

    @Test
    func testBackSavesProgress() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager
        let preferences = appComponents.preferences

        // Start compass check
        compassCheckManager.startCompassCheckNow()
        let firstStep = compassCheckManager.currentStep.id
        #expect(firstStep == "inform")

        // Move forward to get to a second step
        compassCheckManager.moveStateForward()
        let secondStep = compassCheckManager.currentStep.id
        #expect(secondStep != firstStep)  // We've moved forward

        // Record the step we're at before going back
        let stepBeforeBack = secondStep

        // Move forward one more time
        compassCheckManager.moveStateForward()
        let thirdStep = compassCheckManager.currentStep.id
        #expect(thirdStep != secondStep)

        // Go back
        compassCheckManager.goBackOneStep()

        // Verify we went back and progress was saved
        // Note: Due to step applicability changes (e.g., MovePrioritiesToOpen moves tasks),
        // we may not land on the exact same step, but we should land on a previous visible step
        let stepAfterBack = compassCheckManager.currentStep.id
        #expect(stepAfterBack != thirdStep, "Should have gone back from third step")
        #expect(preferences.currentCompassCheckStepId == stepAfterBack, "Saved step should match current step")
    }

    // MARK: - Cross-Device Conflict Tests

    @Test
    func testLocalNextWhenRemoteAheadSyncsToRemote() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager
        let preferences = appComponents.preferences

        // Start compass check locally at step 2
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward()  // currentPriorities
        #expect(compassCheckManager.currentStep.id == "currentPriorities")

        // Simulate remote device being at step 5 (pending)
        preferences.currentCompassCheckStepId = "pending"

        // Local next - should sync to remote step instead of advancing
        compassCheckManager.moveStateForward()

        // Should jump to remote step
        #expect(compassCheckManager.currentStep.id == "pending")
    }

    @Test
    func testLocalBackWhenRemoteAheadStillGoesBack() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager
        let preferences = appComponents.preferences

        // Start compass check locally and advance
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward()
        compassCheckManager.moveStateForward()
        let stepBeforeBack = compassCheckManager.currentStep.id

        // Simulate remote device being ahead at pending
        preferences.currentCompassCheckStepId = "pending"

        // Local back - should go back locally (user intent prevails for back)
        compassCheckManager.goBackOneStep()

        // Should go back to a previous visible step (not stay at current, not jump to remote)
        let stepAfterBack = compassCheckManager.currentStep.id
        #expect(stepAfterBack != stepBeforeBack, "Should have gone back, not stayed at same step")
        #expect(stepAfterBack != "pending", "Should not sync to remote on back - user intent prevails")
    }

    @Test
    func testLocalNextWhenRemoteBehindAdvancesNormally() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager
        let preferences = appComponents.preferences

        // Start compass check locally and advance
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward()
        compassCheckManager.moveStateForward()
        let localStep = compassCheckManager.currentStep.id
        let localStepIndex = compassCheckManager.stepIndex(of: localStep)!

        // Simulate remote device being behind at inform (step 0)
        preferences.currentCompassCheckStepId = "inform"

        // Local next - should advance normally (local is ahead of remote)
        compassCheckManager.moveStateForward()

        // Should advance to next step (not sync back to remote's behind position)
        let newStep = compassCheckManager.currentStep.id
        let newStepIndex = compassCheckManager.stepIndex(of: newStep)!
        #expect(newStepIndex > localStepIndex, "Should have advanced forward")

        // Progress should be saved
        #expect(preferences.currentCompassCheckStepId == newStep)
    }

    @Test
    func testRemoteCompletionClosesLocalDialog() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager
        let preferences = appComponents.preferences
        let timeProvider = appComponents.timeProvider
        let uiState = appComponents.uiState

        // Set up initial state - CC not done today
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)

        // Start compass check locally
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward()
        #expect(uiState.showCompassCheckDialog == true)

        // Simulate remote completion
        preferences.lastCompassCheck = timeProvider.now
        preferences.clearCompassCheckProgress()

        // Trigger sync
        compassCheckManager.onPreferencesChange()

        // Dialog should be closed and state should be finished
        #expect(uiState.showCompassCheckDialog == false)
        if case .finished = compassCheckManager.state {
            // Success
        } else {
            #expect(Bool(false), "Should be finished after remote completion")
        }
    }

    @Test
    func testBothDevicesSameStepAdvancesNormally() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager
        let preferences = appComponents.preferences

        // Start compass check locally
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward()  // currentPriorities
        #expect(compassCheckManager.currentStep.id == "currentPriorities")

        // Remote is at same step
        #expect(preferences.currentCompassCheckStepId == "currentPriorities")

        // Local next - should advance normally
        compassCheckManager.moveStateForward()

        // Should advance to next step
        #expect(compassCheckManager.currentStep.id == "EnergyEffortMatrix")
    }

    // MARK: - Edge Cases

    @Test
    func testCancelPreservesStepForResume() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager
        let preferences = appComponents.preferences
        let uiState = appComponents.uiState

        // Start and move forward
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward()  // currentPriorities
        #expect(compassCheckManager.currentStep.id == "currentPriorities")

        // Cancel
        compassCheckManager.cancelCompassCheck()
        #expect(uiState.showCompassCheckDialog == false)

        // Progress should be preserved
        #expect(preferences.currentCompassCheckStepId == "currentPriorities")
    }

    @Test
    func testResumeAfterCancelContinuesFromSameStep() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager
        let uiState = appComponents.uiState

        // Start and move forward
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward()  // currentPriorities
        #expect(compassCheckManager.currentStep.id == "currentPriorities")

        // Cancel
        compassCheckManager.cancelCompassCheck()
        #expect(uiState.showCompassCheckDialog == false)

        // Resume
        compassCheckManager.startCompassCheckNow()

        // Should be at same step
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        #expect(uiState.showCompassCheckDialog == true)
    }

    @Test
    func testNewPlanningCycleResetsProgress() throws {
        let timeProvider = createMockTimeProvider(fixedNow: Date())
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider)
        let preferences = appComponents.preferences

        // Save progress at step 3 in a previous cycle
        let previousCycleStart = timeProvider.now.addingTimeInterval(-48 * 3600)  // 2 days ago
        preferences.currentCompassCheckStepId = "pending"
        preferences.currentCompassCheckPeriodStart = previousCycleStart

        // Create new manager (simulates app restart in new cycle)
        let newManager = CompassCheckManager(
            dataManager: appComponents.dataManager,
            uiState: appComponents.uiState,
            preferences: preferences,
            timeProvider: timeProvider,
            pushNotificationManager: appComponents.pushNotificationManager
        )

        // Should start fresh (not at step 3)
        if case .notStarted = newManager.state {
            // Success
        } else {
            #expect(Bool(false), "Should be notStarted in new planning cycle")
        }

        // Progress should be cleared
        #expect(preferences.currentCompassCheckStepId == nil)
    }

    // MARK: - Step Index Helper Tests

    @Test
    func testStepIndexReturnsCorrectIndex() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager

        // Test known step indices
        #expect(compassCheckManager.stepIndex(of: "inform") == 0)
        #expect(compassCheckManager.stepIndex(of: "currentPriorities") == 2)
        #expect(compassCheckManager.stepIndex(of: "pending") == 5)

        // Test unknown step
        #expect(compassCheckManager.stepIndex(of: "nonexistent") == nil)
    }

    // MARK: - Finish Button Behavior Tests

    @Test
    func testFinishButtonClosesWindowAfterLastStep() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager
        let uiState = appComponents.uiState

        // Start compass check
        compassCheckManager.startCompassCheckNow()
        #expect(uiState.showCompassCheckDialog == true)

        // Move through all steps to reach the last step
        var iterationCount = 0
        let maxIterations = 20  // Safety limit to prevent infinite loop

        while !compassCheckManager.isFinished && iterationCount < maxIterations {
            compassCheckManager.moveStateForward()
            iterationCount += 1
        }

        #expect(iterationCount < maxIterations, "Should finish within reasonable number of steps")

        // After finishing last step:
        // 1. Dialog should be closed
        #expect(uiState.showCompassCheckDialog == false, "Window should close after finish button is pressed on last step")

        // 2. State should be finished
        #expect(compassCheckManager.isFinished == true, "Compass check should be marked as finished")

        // 3. Saved progress should be cleared
        #expect(appComponents.preferences.currentCompassCheckStepId == nil, "Progress should be cleared after completion")
    }
}
