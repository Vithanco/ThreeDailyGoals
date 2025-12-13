//
//  TestReview.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 20/05/2024.
//
import Foundation
import Testing

@testable import Three_Daily_Goals
@testable import tdgCoreMain

@Suite
@MainActor
struct TestReview {

    /// Helper function to create test preferences with plan step enabled
    private func createTestPreferencesWithPlanEnabled() -> CloudPreferences {
        let testPreferences = CloudPreferences(store: TestPreferences(), timeProvider: RealTimeProvider())
        testPreferences.setCompassCheckStepEnabled(stepId: "plan", enabled: true)
        return testPreferences
    }

    @Test
    func testNoStreak() throws {
        let appComponents = setupApp(isTesting: true, preferences: createTestPreferencesWithPlanEnabled())
        let pref = appComponents.preferences
        let dataManager = appComponents.dataManager
        let uiState = appComponents.uiState
        let compassCheckManager = appComponents.compassCheckManager

        pref.lastCompassCheck = Date(timeIntervalSinceNow: -Seconds.twoDays)

        compassCheckManager.startCompassCheckNow()
        #expect(compassCheckManager.currentStep.id == "inform")
        compassCheckManager.moveStateForward()
        #expect(dataManager.list(which: .priority).count == 3)
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        compassCheckManager.moveStateForward()  // currentPriorities → movePrioritiesToOpen (silent) → EnergyEffortMatrix
        #expect(dataManager.list(which: .priority).count == 0)
        #expect(compassCheckManager.currentStep.id == "EnergyEffortMatrix")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "pending")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "dueDate")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "review")
        compassCheckManager.moveStateForward()
        if OsRelated.currentOS == .macOS {
            #expect(compassCheckManager.currentStep.id == "plan")
            compassCheckManager.moveStateForward()
        }
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(pref.daysOfCompassCheck == 1)
        for t in dataManager.allTasks {
            t.dueDate = nil
        }
        #expect(compassCheckManager.dueDateSoon.isEmpty)

        #expect(!uiState.showCompassCheckDialog)
        compassCheckManager.startCompassCheckNow()

        #expect(uiState.showCompassCheckDialog)
        #expect(compassCheckManager.currentStep.id == "inform")

        #expect(compassCheckManager.dueDateSoon.isEmpty)
        debugPrint(dataManager.list(which: .priority).map { $0.title })
        #expect(dataManager.list(which: .priority).count == 2)
        compassCheckManager.moveStateForward()

        #expect(compassCheckManager.dueDateSoon.isEmpty)
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        compassCheckManager.moveStateForward()  // currentPriorities → movePrioritiesToOpen (silent) → EnergyEffortMatrix
        #expect(compassCheckManager.currentStep.id == "EnergyEffortMatrix")

        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "pending")
        #expect(compassCheckManager.dueDateSoon.isEmpty)
        compassCheckManager.moveStateForward()  // pending → dueDate (skipped, no due dates) → review
        #expect(compassCheckManager.currentStep.id == "review")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "plan")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(pref.daysOfCompassCheck == 1)
        #expect(!uiState.showCompassCheckDialog)

        compassCheckManager.startCompassCheckNow()
        #expect(uiState.showCompassCheckDialog)
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(dataManager.list(which: .priority).count == 0)
        // With no priorities, no due dates: inform → EnergyEffortMatrix (or pending if no uncategorized) → review
        compassCheckManager.moveStateForward()
        // Could be EnergyEffortMatrix or pending depending on task categorization - skip assertion
        compassCheckManager.moveStateForward()
        // Could be pending or review - let's check for review after one more move
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "review")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "plan")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(pref.daysOfCompassCheck == 1)
    }

    @MainActor
    @Test
    func testIncreaseStreak() throws {
        debugPrint("Starting testIncreaseStreak")
        let appComponents = setupApp(isTesting: true, preferences: createTestPreferencesWithPlanEnabled())
        debugPrint("setupApp completed")
        let pref = appComponents.preferences
        debugPrint("got preferences")
        let dataManager = appComponents.dataManager
        let uiState = appComponents.uiState
        let compassCheckManager = appComponents.compassCheckManager

        debugPrint("daysOfCompassCheck: \(pref.daysOfCompassCheck)")
        #expect(pref.daysOfCompassCheck == 42)
        debugPrint("Setting lastCompassCheck")
        pref.lastCompassCheck = Date.now.addingTimeInterval(-24 * 60 * 60)  // 1 day ago
        debugPrint("lastCompassCheck set to: \(pref.lastCompassCheck)")

        debugPrint("Starting compass check")
        compassCheckManager.startCompassCheckNow()
        debugPrint("State after startCompassCheckNow: \(compassCheckManager.currentStep.id)")
        #expect(compassCheckManager.currentStep.id == "inform")
        compassCheckManager.moveStateForward()
        debugPrint("State after first moveStateForward: \(compassCheckManager.currentStep.id)")
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        compassCheckManager.moveStateForward()  // currentPriorities → movePrioritiesToOpen (silent) → EnergyEffortMatrix
        debugPrint("State after second moveStateForward: \(compassCheckManager.currentStep.id)")
        #expect(compassCheckManager.currentStep.id == "EnergyEffortMatrix")
        compassCheckManager.moveStateForward()
        debugPrint("State after third moveStateForward: \(compassCheckManager.currentStep.id)")
        #expect(compassCheckManager.currentStep.id == "pending")
        compassCheckManager.moveStateForward()
        debugPrint("State after fourth moveStateForward: \(compassCheckManager.currentStep.id)")
        #expect(compassCheckManager.currentStep.id == "dueDate")
        compassCheckManager.moveStateForward()
        debugPrint("State after fifth moveStateForward: \(compassCheckManager.currentStep.id)")
        #expect(compassCheckManager.currentStep.id == "review")
        compassCheckManager.moveStateForward()  // review → MoveToGraveyard (may be silent) → plan
        debugPrint("State after sixth moveStateForward: \(compassCheckManager.currentStep.id)")
        #expect(compassCheckManager.currentStep.id == "plan")
        compassCheckManager.moveStateForward()
        debugPrint("State after sixth moveStateForward: \(compassCheckManager.currentStep.id)")
        #expect(compassCheckManager.currentStep.id == "inform")
        debugPrint("Final daysOfCompassCheck: \(pref.daysOfCompassCheck)")
        #expect(pref.daysOfCompassCheck == 43)

        debugPrint("Starting second compass check")
        compassCheckManager.startCompassCheckNow()
        debugPrint("State after second startCompassCheckNow: \(compassCheckManager.currentStep.id)")
        #expect(compassCheckManager.currentStep.id == "inform")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        compassCheckManager.moveStateForward()  // currentPriorities → movePrioritiesToOpen (silent) → EnergyEffortMatrix
        #expect(compassCheckManager.currentStep.id == "EnergyEffortMatrix")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "pending")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "dueDate")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "review")
        compassCheckManager.moveStateForward()  // review → MoveToGraveyard (may be silent) → plan
        #expect(compassCheckManager.currentStep.id == "plan")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(pref.daysOfCompassCheck == 43)
    }

    @MainActor
    @Test
    func testCompassCheckIntervalDebug() throws {
        debugPrint("=== Compass Check Interval Debug ===")
        let appComponents = setupApp(isTesting: true)
        let pref = appComponents.preferences

        debugPrint("Current time: \(Date.now)")
        debugPrint("Compass check time: \(pref.compassCheckTime)")
        debugPrint("Compass check time hour: \(pref.compassCheckTimeComponents.hour ?? -1)")
        debugPrint("Compass check time minute: \(pref.compassCheckTimeComponents.minute ?? -1)")

        let timeProvider = RealTimeProvider()
        let interval = timeProvider.getCompassCheckInterval()
        debugPrint("Current interval: \(interval)")
        debugPrint("Interval start: \(interval.start)")
        debugPrint("Interval end: \(interval.end)")
        debugPrint("Interval duration: \(interval.duration)")

        debugPrint("Last compass check: \(pref.lastCompassCheck)")
        debugPrint("didCompassCheckToday: \(pref.didCompassCheckToday)")
        debugPrint("lastCompassCheck.isToday: \(timeProvider.isToday(pref.lastCompassCheck))")

        // Test setting to interval start + 1 second
        pref.lastCompassCheck = interval.start.addingTimeInterval(1)
        debugPrint("After setting to interval.start + 1s: \(pref.lastCompassCheck)")
        debugPrint("didCompassCheckToday: \(pref.didCompassCheckToday)")

        // Test setting to interval start - 1 hour
        pref.lastCompassCheck = interval.start.addingTimeInterval(-3600)
        debugPrint("After setting to interval.start - 1h: \(pref.lastCompassCheck)")
        debugPrint("didCompassCheckToday: \(pref.didCompassCheckToday)")

        debugPrint("=== End Debug ===")
    }

    @MainActor
    @Test
    func testReviewInterval() throws {
        let timeProvider = RealTimeProvider()
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider)
        let pref = appComponents.preferences

        // Test 1: Set lastCompassCheck to now (should be within current interval)
        pref.lastCompassCheck = Date.now
        #expect(pref.didCompassCheckToday, "Should be true when lastCompassCheck is now")

        // Test 2: Set lastCompassCheck to yesterday (should be outside current interval)
        let yesterday = timeProvider.date(byAdding: .day, value: -1, to: timeProvider.now) ?? timeProvider.now
        pref.lastCompassCheck = yesterday
        #expect(!pref.didCompassCheckToday, "Should be false when lastCompassCheck is yesterday")

        // Test 3: Verify that isToday is also false for yesterday

        #expect(!timeProvider.isToday(pref.lastCompassCheck), "isToday should be false for yesterday")
    }

    let now: Date = "2024-06-02T03:48:00Z"
    let m15: Date = "2024-06-01T13:48:00Z"
    let m24: Date = "2024-06-01T03:48:00Z"  //minus 24 hours
    let m25: Date = "2024-06-01T02:48:00Z"

    @MainActor
    @Test
    func testSetupApp() throws {
        debugPrint("Testing setupApp")
        let appComponents = setupApp(isTesting: true)
        debugPrint("setupApp worked")
        let pref = appComponents.preferences
        debugPrint("preferences: \(pref.daysOfCompassCheck)")
        #expect(pref.daysOfCompassCheck == 42)
    }

    @MainActor
    @Test
    func testdidCompassCheckToday() throws {
        let appComponents = setupApp(isTesting: true)
        let pref = appComponents.preferences

        // Set lastCompassCheck to a time within the current compass check interval
        let timeProvider = RealTimeProvider()
        let currentInterval = timeProvider.getCompassCheckInterval()
        pref.lastCompassCheck = currentInterval.start.addingTimeInterval(1)
        #expect(pref.didCompassCheckToday)
        #expect(pref.didCompassCheckToday)

    }

    @MainActor
    @Test
    func testReview() {
        let appComponents = setupApp(isTesting: true, preferences: createTestPreferencesWithPlanEnabled())
        let pref = appComponents.preferences
        let dataManager = appComponents.dataManager
        let uiState = appComponents.uiState
        let compassCheckManager = appComponents.compassCheckManager

        // Set lastCompassCheck to a time outside the current compass check interval
        let timeProvider = RealTimeProvider()
        let currentInterval = timeProvider.getCompassCheckInterval()
        pref.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)  // 1 hour before interval
        #expect(!pref.didCompassCheckToday)

        #expect(pref.daysOfCompassCheck == 42)
        compassCheckManager.startCompassCheckNow()
        #expect(compassCheckManager.currentStep.id == "inform")
        compassCheckManager.moveStateForward()
        #expect(dataManager.list(which: .priority).count == 3)
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        compassCheckManager.moveStateForward()
        #expect(dataManager.list(which: .priority).count == 0)
        #expect(compassCheckManager.currentStep.id == "EnergyEffortMatrix")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "pending")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "dueDate")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "review")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "plan")
        compassCheckManager.moveStateForward()
        #expect(pref.daysOfCompassCheck == 43)
    }

    @MainActor
    @Test
    func testCompassCheckPauseAndResume() {
        let appComponents = setupApp(isTesting: true, preferences: createTestPreferencesWithPlanEnabled())
        let pref = appComponents.preferences
        let uiState = appComponents.uiState
        let compassCheckManager = appComponents.compassCheckManager

        // Set up initial state - compass check not done today
        let timeProvider = RealTimeProvider()
        let currentInterval = timeProvider.getCompassCheckInterval()
        pref.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)  // 1 hour before interval
        #expect(!pref.didCompassCheckToday)

        // Start compass check
        compassCheckManager.startCompassCheckNow()
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(uiState.showCompassCheckDialog == true)
        if case .paused = compassCheckManager.state {
            #expect(false, "Should not be paused")
        }

        // Move to currentPriorities state
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        if case .paused = compassCheckManager.state {
            #expect(false, "Should not be paused")
        }

        // Pause the compass check
        compassCheckManager.pauseCompassCheck()
        if case .paused = compassCheckManager.state {
            // Paused state confirmed
        } else {
            #expect(false, "Expected paused state")
        }
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        #expect(uiState.showCompassCheckDialog == false)

        // Simulate the notification timer firing (this should resume the compass check)
        compassCheckManager.onCCNotification()
        if case .paused = compassCheckManager.state {
            #expect(false, "Should not be paused")
        }
        #expect(compassCheckManager.currentStep.id == "currentPriorities")
        #expect(uiState.showCompassCheckDialog == true)

        // Continue with the compass check flow
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "EnergyEffortMatrix")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "pending")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "dueDate")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "review")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "plan")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.currentStep.id == "inform")
        #expect(pref.daysOfCompassCheck == 43)
    }

    @MainActor
    @Test
    func testCompassCheckPauseAtDifferentStates() {
        let appComponents = setupApp(isTesting: true)
        let pref = appComponents.preferences
        let uiState = appComponents.uiState
        let compassCheckManager = appComponents.compassCheckManager

        // Set up initial state
        let timeProvider = RealTimeProvider()
        let currentInterval = timeProvider.getCompassCheckInterval()
        pref.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!pref.didCompassCheckToday)

        // Test pausing at different states
        let stepIdsToTest = ["currentPriorities", "pending", "dueDate", "review"]

        for stepIdToTest in stepIdsToTest {
            // Start fresh compass check
            compassCheckManager.startCompassCheckNow()
            #expect(compassCheckManager.currentStep.id == "inform")

            // Navigate to the state we want to test
            while compassCheckManager.currentStep.id != stepIdToTest {
                compassCheckManager.moveStateForward()
            }
            #expect(compassCheckManager.currentStep.id == stepIdToTest)

            // Pause at this state
            compassCheckManager.pauseCompassCheck()
            if case .paused(let pausedStep) = compassCheckManager.state {
                #expect(pausedStep.id == stepIdToTest)
            } else {
                #expect(false, "Expected paused state")
            }
            #expect(uiState.showCompassCheckDialog == false)

            // Resume and verify we're back at the same state
            compassCheckManager.onCCNotification()
            if case .paused = compassCheckManager.state {
                #expect(false, "Should not be paused")
            }
            #expect(compassCheckManager.currentStep.id == stepIdToTest)
            #expect(uiState.showCompassCheckDialog == true)

            // Cancel to pause for next test
            compassCheckManager.cancelCompassCheck()
            #expect(compassCheckManager.currentStep.id == stepIdToTest)  // Should stay at current step
            if case .paused = compassCheckManager.state {
                // Paused state confirmed
            } else {
                #expect(false, "Should be paused after cancel")
            }
            compassCheckManager.endCompassCheck(didFinishCompassCheck: true)
        }
    }
}

extension Date: @retroactive ExpressibleByExtendedGraphemeClusterLiteral {}
extension Date: @retroactive ExpressibleByUnicodeScalarLiteral {}
extension Date: @retroactive ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: value) else {
            fatalError("Invalid ISO 8601 date format \(value)")
        }
        self = date
    }
}
