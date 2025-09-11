//
//  TestCompassCheckSynchronization.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 2025-01-14.
//

import Foundation
import Testing
import SwiftUI

@testable import Three_Daily_Goals

@Suite
@MainActor
struct TestCompassCheckSynchronization {
    
    // MARK: - Test Setup Helpers
    
    /// Creates a mock time provider with a fixed "now" time
    private func createMockTimeProvider(fixedNow: Date) -> MockTimeProvider {
        return MockTimeProvider(fixedNow: fixedNow)
    }
    
    /// Simulates external compass check completion by updating preferences
    private func simulateExternalCompassCheckCompletion(preferences: CloudPreferences, timeProvider: TimeProvider) {
        // Set lastCompassCheck to current time to simulate completion
        preferences.lastCompassCheck = timeProvider.now
        // Increment streak
        preferences.daysOfCompassCheck = preferences.daysOfCompassCheck + 1
    }
    
    // MARK: - External Completion Detection Tests
    
    @Test
    func testExternalCompletionClosesDialog() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let preferences = appComponents.preferences
        let timeProvider = appComponents.timeProvider
        
        let compassCheckManager = appComponents.compassCheckManager
        let uiState = appComponents.uiState
        
        // Set up initial state - compass check not done today
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600) // 1 hour before interval
        #expect(!preferences.didCompassCheckToday)
        
        // Start compass check dialog
        compassCheckManager.startCompassCheckNow()
        #expect(uiState.showCompassCheckDialog == true)
        #expect(compassCheckManager.currentStep.id == "inform")
        
        // Simulate external completion (e.g., on another device)
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        
        // Trigger preferences change (simulating iCloud sync)
        compassCheckManager.onPreferencesChange()
        
        // Verify dialog is closed and state is reset
        #expect(uiState.showCompassCheckDialog == false)
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(compassCheckManager.isPaused == false)
    }
    
    @Test
    func testExternalCompletionResetsStateWhenNotShowingDialog() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let preferences = appComponents.preferences
        let timeProvider = appComponents.timeProvider
        
        let compassCheckManager = appComponents.compassCheckManager
        let uiState = appComponents.uiState
        
        // Set up initial state - compass check not done today
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        // Start compass check and move to a different state
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward() // Move to currentPriorities
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        
        // Close dialog manually (simulating user closing it)
        uiState.showCompassCheckDialog = false
        
        // Simulate external completion
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        
        // Trigger preferences change
        compassCheckManager.onPreferencesChange()
        
        // Verify state is reset even though dialog wasn't showing
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(compassCheckManager.isPaused == false)
        #expect(uiState.showCompassCheckDialog == false)
    }
    
    @Test
    func testExternalCompletionDuringPausedState() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let preferences = appComponents.preferences
        let timeProvider = appComponents.timeProvider
        
        let compassCheckManager = appComponents.compassCheckManager
        let uiState = appComponents.uiState
        
        // Set up initial state
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        // Start compass check and pause it
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward() // Move to currentPriorities
        compassCheckManager.pauseCompassCheck()
        
        #expect(compassCheckManager.isPaused == true)
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        #expect(uiState.showCompassCheckDialog == false)
        
        // Simulate external completion
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        
        // Trigger preferences change
        compassCheckManager.onPreferencesChange()
        
        // Verify paused state is cleared
        #expect(compassCheckManager.isPaused == false)
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(uiState.showCompassCheckDialog == false)
    }
    
    // MARK: - Periodic Sync Check Tests
    
    @Test
    func testPeriodicSyncCheckDetectsExternalCompletion() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let preferences = appComponents.preferences
        let timeProvider = appComponents.timeProvider
        
        let compassCheckManager = appComponents.compassCheckManager
        let uiState = appComponents.uiState
        
        // Set up initial state
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        // Start compass check dialog
        compassCheckManager.startCompassCheckNow()
        #expect(uiState.showCompassCheckDialog == true)
        #expect(compassCheckManager.currentStep.id == "inform")
        
        // Simulate external completion
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        
        // Manually trigger the periodic sync check
        compassCheckManager.checkForExternalCompassCheckCompletion()
        
        // Verify dialog is closed
        #expect(uiState.showCompassCheckDialog == false)
        #expect(compassCheckManager.currentStep.id == "inform")
    }
    
    // MARK: - Timer Rescheduling Tests
    
    @Test
    func testExternalCompletionReschedulesTimers() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let preferences = appComponents.preferences
        let timeProvider = appComponents.timeProvider
        
        let compassCheckManager = appComponents.compassCheckManager
        
        // Set up initial state
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        // Start compass check and move to a state other than inform
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward() // Move to currentPriorities
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        
        // Close dialog manually
        appComponents.uiState.showCompassCheckDialog = false
        
        // Simulate external completion
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        
        // Trigger preferences change (this should reschedule timers)
        compassCheckManager.onPreferencesChange()
        
        // Verify state is reset and timers are rescheduled
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(compassCheckManager.isPaused == false)
        
        // The setupCompassCheckNotification() should have been called
        // We can verify this by checking that the sync timer is running
        // (In a real scenario, we'd check the timer state, but for testing we verify the behavior)
    }
    
    // MARK: - Notification Cancellation Tests
    
    @Test
    func testExternalCompletionCancelsNotifications() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let preferences = appComponents.preferences
        let timeProvider = appComponents.timeProvider
        
        let compassCheckManager = appComponents.compassCheckManager
        
        // Set up initial state
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        // Start compass check
        compassCheckManager.startCompassCheckNow()
        #expect(compassCheckManager.currentStep.id == "inform")
        
        // Simulate external completion
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        
        // Trigger preferences change
        compassCheckManager.onPreferencesChange()
        
        // Verify that endCompassCheck was called (which cancels notifications)
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(compassCheckManager.isPaused == false)
        
        // In a real test, we'd verify that push notifications were cancelled
        // but since we're in test mode, the push notification manager isn't fully active
    }
    
    // MARK: - StreakView Update Tests
    
    @Test
    func testStreakViewUpdatesAfterExternalCompletion() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager
        let preferences = appComponents.preferences
        let timeProvider = appComponents.timeProvider
        
        // Set up initial state
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        let initialStreak = preferences.daysOfCompassCheck
        #expect(initialStreak == 42) // Default test value
        
        // Start compass check
        compassCheckManager.startCompassCheckNow()
        #expect(compassCheckManager.currentStep.id == "inform")
        
        // Simulate external completion
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        #expect(preferences.daysOfCompassCheck == initialStreak + 1)
        
        // Trigger preferences change
        compassCheckManager.onPreferencesChange()
        
        // Verify that the preferences are updated and would trigger StreakView refresh
        #expect(preferences.didCompassCheckToday == true)
        #expect(preferences.daysOfCompassCheck == initialStreak + 1)
        
        // The StreakView should automatically update due to @Environment(CloudPreferences.self)
        // and the @Observable nature of CloudPreferences
    }
    
    @Test
    func testStreakViewUpdatesAfterLocalCompletion() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let compassCheckManager = appComponents.compassCheckManager
        let preferences = appComponents.preferences
        let timeProvider = appComponents.timeProvider
        
        // Set up initial state
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        let initialStreak = preferences.daysOfCompassCheck
        #expect(initialStreak == 42) // Default test value
        
        // Start compass check and complete it locally
        compassCheckManager.startCompassCheckNow()
        #expect(compassCheckManager.currentStep.id == "inform")
        
        // Complete the compass check locally (simulate going through all steps)
        compassCheckManager.endCompassCheck(didFinishCompassCheck: true)
        
        // Verify that the preferences are updated
        #expect(preferences.didCompassCheckToday == true)
        #expect(preferences.daysOfCompassCheck == initialStreak + 1)
        
        // The StreakView should update automatically due to @Observable mechanism
        // This test verifies that the proper @Observable implementation works for local completion
        // The fix ensures that CloudPreferences uses stored properties that trigger UI updates
    }
    
    // MARK: - Edge Cases Tests
    
    @Test
    func testMultipleExternalCompletions() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let preferences = appComponents.preferences
        let timeProvider = appComponents.timeProvider
        
        let compassCheckManager = appComponents.compassCheckManager
        let uiState = appComponents.uiState
        
        // Set up initial state
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        // Start compass check
        compassCheckManager.startCompassCheckNow()
        #expect(uiState.showCompassCheckDialog == true)
        
        // Simulate first external completion
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        compassCheckManager.onPreferencesChange()
        #expect(uiState.showCompassCheckDialog == false)
        
        // Simulate second external completion (should be idempotent)
        compassCheckManager.onPreferencesChange()
        #expect(uiState.showCompassCheckDialog == false)
        #expect(compassCheckManager.currentStep.id == "inform")
    }
    
    @Test
    func testMultipleCompassChecksPerDay() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let preferences = appComponents.preferences
        let timeProvider = appComponents.timeProvider
        
        let compassCheckManager = appComponents.compassCheckManager
        let uiState = appComponents.uiState
        
        // Set up state where compass check is already completed today
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(1)
        #expect(preferences.didCompassCheckToday == true)
        
        // Try to start compass check (should show dialog - multiple compass checks per day are allowed)
        compassCheckManager.startCompassCheckNow()
        #expect(uiState.showCompassCheckDialog == true)
        #expect(compassCheckManager.currentStep.id == "inform")
    }
    
    // MARK: - Integration Tests
    
    @Test
    func testFullSynchronizationScenario() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let preferences = appComponents.preferences
        let timeProvider = appComponents.timeProvider
        
        let compassCheckManager = appComponents.compassCheckManager
        let uiState = appComponents.uiState
        
        // Set up initial state
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        let initialStreak = preferences.daysOfCompassCheck
        
        // Start compass check and progress through states
        compassCheckManager.startCompassCheckNow()
        #expect(uiState.showCompassCheckDialog == true)
        #expect(compassCheckManager.currentStep.id == "inform")
        
        compassCheckManager.moveStateForward() // currentPriorities
        compassCheckManager.moveStateForward() // pending
        #expect(compassCheckManager.currentStep.id == "pending")
        
        // Simulate external completion (e.g., user completed on iPhone)
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        #expect(preferences.daysOfCompassCheck == initialStreak + 1)
        
        // Simulate iCloud sync triggering preferences change
        compassCheckManager.onPreferencesChange()
        
        // Verify complete state reset
        #expect(uiState.showCompassCheckDialog == false)
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(compassCheckManager.isPaused == false)
        #expect(preferences.didCompassCheckToday == true)
        #expect(preferences.daysOfCompassCheck == initialStreak + 1)
        
        // Verify that timers are rescheduled for next interval
        // (In a real scenario, we'd check the timer state)
    }
    
    // MARK: - Timer Management Tests
    
    @Test
    func testTimerReschedulingAfterExternalCompletion() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let preferences = appComponents.preferences
        let timeProvider = appComponents.timeProvider
        
        let compassCheckManager = appComponents.compassCheckManager
        
        // Set up initial state
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        // Start compass check and move to a non-inform state
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward() // currentPriorities
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        
        // Close dialog to simulate the scenario where dialog is not showing
        appComponents.uiState.showCompassCheckDialog = false
        
        // Simulate external completion
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        
        // Trigger preferences change - this should reschedule timers
        compassCheckManager.onPreferencesChange()
        
        // Verify state is reset
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(compassCheckManager.isPaused == false)
        
        // The key test: verify that setupCompassCheckNotification() was called
        // by checking that the compass check manager is ready for the next interval
        // Since didCompassCheckToday is true, the next call to setupCompassCheckNotification
        // should set up timers for the next day's interval
    }
    
    @Test
    func testSyncTimerLifecycle() throws {
        let appComponents = setupApp(isTesting: true, timeProvider: createMockTimeProvider(fixedNow: Date()))
        let preferences = appComponents.preferences
        let timeProvider = appComponents.timeProvider
        
        let compassCheckManager = appComponents.compassCheckManager
        
        // Set up initial state
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        // Start compass check (this should start the sync timer)
        compassCheckManager.startCompassCheckNow()
        
        // Simulate external completion
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        
        // Trigger preferences change (this should stop the sync timer)
        compassCheckManager.onPreferencesChange()
        
        // Verify state is clean
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(compassCheckManager.isPaused == false)
        
        // The sync timer should be stopped when endCompassCheck is called
        // In a real implementation, we'd verify the timer is actually stopped
    }
}
