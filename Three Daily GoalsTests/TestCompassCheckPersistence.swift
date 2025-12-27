//
//  TestCompassCheckPersistence.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 2025-12-14.
//

import Foundation
import SwiftUI
import Testing

@testable import Three_Daily_Goals
@testable import tdgCoreMain

@Suite
@MainActor
struct TestCompassCheckPersistence {

    // MARK: - Test Setup Helpers

    /// Creates a mock time provider with a fixed "now" time
    private func createMockTimeProvider(fixedNow: Date) -> MockTimeProvider {
        return MockTimeProvider(fixedNow: fixedNow)
    }

    // MARK: - State Persistence Tests

    @Test
    func testStepProgressIsSavedAfterMoveForward() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager
        let preferences = appComponents.preferences

        // Start compass check
        compassCheckManager.startCompassCheckNow()
        #expect(compassCheckManager.currentStep.id == "inform")

        // Verify initial save
        #expect(preferences.currentCompassCheckStepId == "inform")
        #expect(preferences.currentCompassCheckPeriodStart != nil)

        // Move forward
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "currentPriorities")

        // Verify progress was saved
        #expect(preferences.currentCompassCheckStepId == "currentPriorities")
    }

    @Test
    func testProgressIsClearedAfterFinish() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager
        let preferences = appComponents.preferences

        // Start and save some progress
        compassCheckManager.startCompassCheckNow()
        #expect(preferences.currentCompassCheckStepId != nil)

        // Finish compass check
        compassCheckManager.endCompassCheck(didFinishCompassCheck: true)

        // Verify progress was cleared
        #expect(preferences.currentCompassCheckStepId == nil)
        #expect(preferences.currentCompassCheckPeriodStart == nil)
    }

    @Test
    func testProgressIsLoadedOnInit() throws {
        let timeProvider = createMockTimeProvider(fixedNow: Date())
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider)
        let preferences = appComponents.preferences

        // Manually set saved progress
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.currentCompassCheckStepId = "pending"
        preferences.currentCompassCheckPeriodStart = currentInterval.start

        // Create a new manager (simulating app restart)
        let newManager = CompassCheckManager(
            dataManager: appComponents.dataManager,
            uiState: appComponents.uiState,
            preferences: preferences,
            timeProvider: timeProvider,
            pushNotificationManager: appComponents.pushNotificationManager
        )

        // Should load paused state
        if case .paused(let step) = newManager.state {
            #expect(step.id == "pending")
        } else {
            #expect(Bool(false), "State should be paused with pending step")
        }
    }

    @Test
    func testProgressIsResetIfReviewPeriodChanged() throws {
        let timeProvider = createMockTimeProvider(fixedNow: Date())
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider)
        let preferences = appComponents.preferences

        // Manually set saved progress from previous review period
        let previousPeriodStart = timeProvider.now.addingTimeInterval(-48 * 3600)  // 2 days ago
        preferences.currentCompassCheckStepId = "pending"
        preferences.currentCompassCheckPeriodStart = previousPeriodStart

        // Create a new manager (simulating app restart)
        let newManager = CompassCheckManager(
            dataManager: appComponents.dataManager,
            uiState: appComponents.uiState,
            preferences: preferences,
            timeProvider: timeProvider,
            pushNotificationManager: appComponents.pushNotificationManager
        )

        // Should reset to notStarted because period changed
        if case .notStarted = newManager.state {
            // Success
        } else {
            #expect(Bool(false), "State should be notStarted when review period changed")
        }

        // Progress should be cleared
        #expect(preferences.currentCompassCheckStepId == nil)
        #expect(preferences.currentCompassCheckPeriodStart == nil)
    }

    // MARK: - Cancel Behavior Tests

    @Test
    func testCancelDoesNotChangeState() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager
        let uiState = appComponents.uiState

        // Start and move to a specific step
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "currentPriorities")

        // Cancel
        compassCheckManager.cancelCompassCheck()

        // Dialog should be closed
        #expect(uiState.showCompassCheckDialog == false)

        // State should still be inProgress
        if case .inProgress(let step) = compassCheckManager.state {
            #expect(step.id == "currentPriorities")
        } else {
            #expect(Bool(false), "State should remain inProgress after cancel")
        }
    }

    @Test
    func testResumeFromPausedState() throws {
        let timeProvider = createMockTimeProvider(fixedNow: Date())
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider)
        let preferences = appComponents.preferences

        // Manually set saved progress (simulating previous paused session)
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.currentCompassCheckStepId = "pending"
        preferences.currentCompassCheckPeriodStart = currentInterval.start

        // Create a new manager (simulating app restart)
        let newManager = CompassCheckManager(
            dataManager: appComponents.dataManager,
            uiState: appComponents.uiState,
            preferences: preferences,
            timeProvider: timeProvider,
            pushNotificationManager: appComponents.pushNotificationManager
        )

        // Should start in paused state
        if case .paused(let step) = newManager.state {
            #expect(step.id == "pending")
        } else {
            #expect(Bool(false), "State should be paused")
        }

        // Resume
        newManager.startCompassCheckNow()

        // Should now be in progress at the same step
        if case .inProgress(let step) = newManager.state {
            #expect(step.id == "pending")
        } else {
            #expect(Bool(false), "State should be inProgress after resume")
        }
    }

    // MARK: - Cross-Device Completion Tests

    @Test
    func testExternalCompletionClearsLocalProgress() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let preferences = appComponents.preferences
        let timeProvider = appComponents.timeProvider
        let compassCheckManager = appComponents.compassCheckManager

        // Start compass check locally
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward()
        #expect(preferences.currentCompassCheckStepId != nil)

        // Simulate external completion
        preferences.lastCompassCheck = timeProvider.now
        preferences.clearCompassCheckProgress()

        // Trigger sync
        compassCheckManager.onPreferencesChange()

        // Progress should be cleared
        #expect(preferences.currentCompassCheckStepId == nil)
    }
}
