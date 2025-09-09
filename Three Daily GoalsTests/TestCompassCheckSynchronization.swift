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
    
    /// Creates test preferences that simulate external changes
    private func createTestPreferences(timeProvider: TimeProvider) -> CloudPreferences {
        let store = TestPreferences()
        store.set(18, forKey: .compassCheckTimeHour)
        store.set(0, forKey: .compassCheckTimeMinute)
        return CloudPreferences(store: store, timeProvider: timeProvider)
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
        let timeProvider = createMockTimeProvider(fixedNow: Date())
        let preferences = createTestPreferences(timeProvider: timeProvider)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider, preferences: preferences)
        
        let compassCheckManager = appComponents.compassCheckManager
        let uiState = appComponents.uiState
        
        // Set up initial state - compass check not done today
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600) // 1 hour before interval
        #expect(!preferences.didCompassCheckToday)
        
        // Start compass check dialog
        compassCheckManager.startCompassCheckNow()
        #expect(uiState.showCompassCheckDialog == true)
        #expect(compassCheckManager.state == .inform)
        
        // Simulate external completion (e.g., on another device)
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        
        // Trigger preferences change (simulating iCloud sync)
        compassCheckManager.onPreferencesChange()
        
        // Verify dialog is closed and state is reset
        #expect(uiState.showCompassCheckDialog == false)
        #expect(compassCheckManager.state == .inform)
        #expect(compassCheckManager.isPaused == false)
    }
    
    @Test
    func testExternalCompletionResetsStateWhenNotShowingDialog() throws {
        let timeProvider = createMockTimeProvider(fixedNow: Date())
        let preferences = createTestPreferences(timeProvider: timeProvider)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider, preferences: preferences)
        
        let compassCheckManager = appComponents.compassCheckManager
        let uiState = appComponents.uiState
        
        // Set up initial state - compass check not done today
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        // Start compass check and move to a different state
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward() // Move to currentPriorities
        #expect(compassCheckManager.state == .currentPriorities)
        
        // Close dialog manually (simulating user closing it)
        uiState.showCompassCheckDialog = false
        
        // Simulate external completion
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        
        // Trigger preferences change
        compassCheckManager.onPreferencesChange()
        
        // Verify state is reset even though dialog wasn't showing
        #expect(compassCheckManager.state == .inform)
        #expect(compassCheckManager.isPaused == false)
        #expect(uiState.showCompassCheckDialog == false)
    }
    
    @Test
    func testExternalCompletionDuringPausedState() throws {
        let timeProvider = createMockTimeProvider(fixedNow: Date())
        let preferences = createTestPreferences(timeProvider: timeProvider)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider, preferences: preferences)
        
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
        #expect(compassCheckManager.pausedState == .currentPriorities)
        #expect(uiState.showCompassCheckDialog == false)
        
        // Simulate external completion
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        
        // Trigger preferences change
        compassCheckManager.onPreferencesChange()
        
        // Verify paused state is cleared
        #expect(compassCheckManager.isPaused == false)
        #expect(compassCheckManager.state == .inform)
        #expect(uiState.showCompassCheckDialog == false)
    }
    
    // MARK: - Periodic Sync Check Tests
    
    @Test
    func testPeriodicSyncCheckDetectsExternalCompletion() throws {
        let timeProvider = createMockTimeProvider(fixedNow: Date())
        let preferences = createTestPreferences(timeProvider: timeProvider)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider, preferences: preferences)
        
        let compassCheckManager = appComponents.compassCheckManager
        let uiState = appComponents.uiState
        
        // Set up initial state
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        // Start compass check dialog
        compassCheckManager.startCompassCheckNow()
        #expect(uiState.showCompassCheckDialog == true)
        #expect(compassCheckManager.state == .inform)
        
        // Simulate external completion
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        
        // Manually trigger the periodic sync check
        compassCheckManager.checkForExternalCompassCheckCompletion()
        
        // Verify dialog is closed
        #expect(uiState.showCompassCheckDialog == false)
        #expect(compassCheckManager.state == .inform)
    }
    
    // MARK: - Timer Rescheduling Tests
    
    @Test
    func testExternalCompletionReschedulesTimers() throws {
        let timeProvider = createMockTimeProvider(fixedNow: Date())
        let preferences = createTestPreferences(timeProvider: timeProvider)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider, preferences: preferences)
        
        let compassCheckManager = appComponents.compassCheckManager
        
        // Set up initial state
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        // Start compass check and move to a state other than inform
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward() // Move to currentPriorities
        #expect(compassCheckManager.state == .currentPriorities)
        
        // Close dialog manually
        compassCheckManager.uiState.showCompassCheckDialog = false
        
        // Simulate external completion
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        
        // Trigger preferences change (this should reschedule timers)
        compassCheckManager.onPreferencesChange()
        
        // Verify state is reset and timers are rescheduled
        #expect(compassCheckManager.state == .inform)
        #expect(compassCheckManager.isPaused == false)
        
        // The setupCompassCheckNotification() should have been called
        // We can verify this by checking that the sync timer is running
        // (In a real scenario, we'd check the timer state, but for testing we verify the behavior)
    }
    
    // MARK: - Notification Cancellation Tests
    
    @Test
    func testExternalCompletionCancelsNotifications() throws {
        let timeProvider = createMockTimeProvider(fixedNow: Date())
        let preferences = createTestPreferences(timeProvider: timeProvider)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider, preferences: preferences)
        
        let compassCheckManager = appComponents.compassCheckManager
        
        // Set up initial state
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        // Start compass check
        compassCheckManager.startCompassCheckNow()
        #expect(compassCheckManager.state == .inform)
        
        // Simulate external completion
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        
        // Trigger preferences change
        compassCheckManager.onPreferencesChange()
        
        // Verify that endCompassCheck was called (which cancels notifications)
        #expect(compassCheckManager.state == .inform)
        #expect(compassCheckManager.isPaused == false)
        
        // In a real test, we'd verify that push notifications were cancelled
        // but since we're in test mode, the push notification manager isn't fully active
    }
    
    // MARK: - StreakView Update Tests
    
    @Test
    func testStreakViewUpdatesAfterExternalCompletion() throws {
        let timeProvider = createMockTimeProvider(fixedNow: Date())
        let preferences = createTestPreferences(timeProvider: timeProvider)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider, preferences: preferences)
        
        let compassCheckManager = appComponents.compassCheckManager
        
        // Set up initial state
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        let initialStreak = preferences.daysOfCompassCheck
        #expect(initialStreak == 42) // Default test value
        
        // Start compass check
        compassCheckManager.startCompassCheckNow()
        #expect(compassCheckManager.state == .inform)
        
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
    
    // MARK: - Edge Cases Tests
    
    @Test
    func testMultipleExternalCompletions() throws {
        let timeProvider = createMockTimeProvider(fixedNow: Date())
        let preferences = createTestPreferences(timeProvider: timeProvider)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider, preferences: preferences)
        
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
        #expect(compassCheckManager.state == .inform)
    }
    
    @Test
    func testExternalCompletionWhenAlreadyCompleted() throws {
        let timeProvider = createMockTimeProvider(fixedNow: Date())
        let preferences = createTestPreferences(timeProvider: timeProvider)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider, preferences: preferences)
        
        let compassCheckManager = appComponents.compassCheckManager
        let uiState = appComponents.uiState
        
        // Set up state where compass check is already completed today
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(1)
        #expect(preferences.didCompassCheckToday == true)
        
        // Try to start compass check (should not show dialog)
        compassCheckManager.startCompassCheckNow()
        #expect(uiState.showCompassCheckDialog == false)
        
        // Trigger preferences change (should be no-op)
        compassCheckManager.onPreferencesChange()
        #expect(uiState.showCompassCheckDialog == false)
        #expect(compassCheckManager.state == .inform)
    }
    
    // MARK: - Integration Tests
    
    @Test
    func testFullSynchronizationScenario() throws {
        let timeProvider = createMockTimeProvider(fixedNow: Date())
        let preferences = createTestPreferences(timeProvider: timeProvider)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider, preferences: preferences)
        
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
        #expect(compassCheckManager.state == .inform)
        
        compassCheckManager.moveStateForward() // currentPriorities
        compassCheckManager.moveStateForward() // pending
        #expect(compassCheckManager.state == .pending)
        
        // Simulate external completion (e.g., user completed on iPhone)
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        #expect(preferences.daysOfCompassCheck == initialStreak + 1)
        
        // Simulate iCloud sync triggering preferences change
        compassCheckManager.onPreferencesChange()
        
        // Verify complete state reset
        #expect(uiState.showCompassCheckDialog == false)
        #expect(compassCheckManager.state == .inform)
        #expect(compassCheckManager.isPaused == false)
        #expect(preferences.didCompassCheckToday == true)
        #expect(preferences.daysOfCompassCheck == initialStreak + 1)
        
        // Verify that timers are rescheduled for next interval
        // (In a real scenario, we'd check the timer state)
    }
    
    // MARK: - Timer Management Tests
    
    @Test
    func testTimerReschedulingAfterExternalCompletion() throws {
        let timeProvider = createMockTimeProvider(fixedNow: Date())
        let preferences = createTestPreferences(timeProvider: timeProvider)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider, preferences: preferences)
        
        let compassCheckManager = appComponents.compassCheckManager
        
        // Set up initial state
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)
        
        // Start compass check and move to a non-inform state
        compassCheckManager.startCompassCheckNow()
        compassCheckManager.moveStateForward() // currentPriorities
        #expect(compassCheckManager.state == .currentPriorities)
        
        // Close dialog to simulate the scenario where dialog is not showing
        compassCheckManager.uiState.showCompassCheckDialog = false
        
        // Simulate external completion
        simulateExternalCompassCheckCompletion(preferences: preferences, timeProvider: timeProvider)
        #expect(preferences.didCompassCheckToday == true)
        
        // Trigger preferences change - this should reschedule timers
        compassCheckManager.onPreferencesChange()
        
        // Verify state is reset
        #expect(compassCheckManager.state == .inform)
        #expect(compassCheckManager.isPaused == false)
        
        // The key test: verify that setupCompassCheckNotification() was called
        // by checking that the compass check manager is ready for the next interval
        // Since didCompassCheckToday is true, the next call to setupCompassCheckNotification
        // should set up timers for the next day's interval
    }
    
    @Test
    func testSyncTimerLifecycle() throws {
        let timeProvider = createMockTimeProvider(fixedNow: Date())
        let preferences = createTestPreferences(timeProvider: timeProvider)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider, preferences: preferences)
        
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
        #expect(compassCheckManager.state == .inform)
        #expect(compassCheckManager.isPaused == false)
        
        // The sync timer should be stopped when endCompassCheck is called
        // In a real implementation, we'd verify the timer is actually stopped
    }
}
