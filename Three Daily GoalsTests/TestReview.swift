//
//  TestReview.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 20/05/2024.
//
import Foundation
import Testing

@testable import Three_Daily_Goals

@Suite
@MainActor
struct TestReview {

    @Test
    func testNoStreak() throws {
        let appComponents = setupApp(isTesting: true)
        let pref = appComponents.preferences
        let dataManager = appComponents.dataManager
        let uiState = appComponents.uiState
        let compassCheckManager = appComponents.compassCheckManager

        pref.lastCompassCheck = Date(timeIntervalSinceNow: -Seconds.twoDays)

        compassCheckManager.startCompassCheckNow()
        #expect(compassCheckManager.state.rawValue == "inform")
        compassCheckManager.moveStateForward()
        #expect(dataManager.list(which: .priority).count == 1)
        #expect(compassCheckManager.state.rawValue == "currentPriorities")
        compassCheckManager.moveStateForward()
        #expect(dataManager.list(which: .priority).count == 0)
        #expect(compassCheckManager.state.rawValue == "pending")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "dueDate")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "review")
        compassCheckManager.moveStateForward()
        if OsRelated.currentOS == .macOS {
            #expect(compassCheckManager.state.rawValue == "plan")
            compassCheckManager.moveStateForward()
        }
        #expect(compassCheckManager.state.rawValue == "inform")
        #expect(pref.daysOfCompassCheck == 1)
        for t in dataManager.items {
            t.dueDate = nil
        }
        #expect(compassCheckManager.dueDateSoon.isEmpty)

        #expect(!uiState.showCompassCheckDialog)
        compassCheckManager.startCompassCheckNow()

        #expect(uiState.showCompassCheckDialog)
        #expect(compassCheckManager.state.rawValue == "inform")

        #expect(compassCheckManager.dueDateSoon.isEmpty)
        debugPrint(dataManager.list(which: .priority).map { $0.title })
        #expect(dataManager.list(which: .priority).count == 2)
        compassCheckManager.moveStateForward()

        #expect(compassCheckManager.dueDateSoon.isEmpty)
        #expect(compassCheckManager.state.rawValue == "currentPriorities")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "pending")

        #expect(compassCheckManager.state.rawValue == "pending")
        #expect(compassCheckManager.dueDateSoon.isEmpty)
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "review")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "plan")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "inform")
        #expect(pref.daysOfCompassCheck == 1)
        #expect(!uiState.showCompassCheckDialog)

        compassCheckManager.startCompassCheckNow()
        #expect(uiState.showCompassCheckDialog)
        #expect(compassCheckManager.state.rawValue == "inform")
        #expect(dataManager.list(which: .priority).count == 0)
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "pending")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "review")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "plan")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "inform")
        #expect(pref.daysOfCompassCheck == 1)
    }

    @MainActor
    @Test
    func testIncreaseStreak() throws {
        debugPrint("Starting testIncreaseStreak")
        let appComponents = setupApp(isTesting: true)
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
        debugPrint("State after startCompassCheckNow: \(compassCheckManager.state.rawValue)")
        #expect(compassCheckManager.state.rawValue == "inform")
        compassCheckManager.moveStateForward()
        debugPrint("State after first moveStateForward: \(compassCheckManager.state.rawValue)")
        #expect(compassCheckManager.state.rawValue == "currentPriorities")
        compassCheckManager.moveStateForward()
        debugPrint("State after second moveStateForward: \(compassCheckManager.state.rawValue)")
        #expect(compassCheckManager.state.rawValue == "pending")
        compassCheckManager.moveStateForward()
        debugPrint("State after third moveStateForward: \(compassCheckManager.state.rawValue)")
        #expect(compassCheckManager.state.rawValue == "dueDate")
        compassCheckManager.moveStateForward()
        debugPrint("State after fourth moveStateForward: \(compassCheckManager.state.rawValue)")
        #expect(compassCheckManager.state.rawValue == "review")
        compassCheckManager.moveStateForward()
        debugPrint("State after fifth moveStateForward: \(compassCheckManager.state.rawValue)")
        #expect(compassCheckManager.state.rawValue == "plan")
        compassCheckManager.moveStateForward()
        debugPrint("State after sixth moveStateForward: \(compassCheckManager.state.rawValue)")
        #expect(compassCheckManager.state.rawValue == "inform")
        debugPrint("Final daysOfCompassCheck: \(pref.daysOfCompassCheck)")
        #expect(pref.daysOfCompassCheck == 43)

        debugPrint("Starting second compass check")
        compassCheckManager.startCompassCheckNow()
        debugPrint("State after second startCompassCheckNow: \(compassCheckManager.state.rawValue)")
        #expect(compassCheckManager.state.rawValue == "inform")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "currentPriorities")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "pending")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "dueDate")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "review")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "plan")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "inform")
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
        let appComponents = setupApp(isTesting: true,timeProvider: timeProvider)
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
        let appComponents = setupApp(isTesting: true)
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
        #expect(compassCheckManager.state.rawValue == "inform")
        compassCheckManager.moveStateForward()
        #expect(dataManager.list(which: .priority).count == 1)
        #expect(compassCheckManager.state.rawValue == "currentPriorities")
        compassCheckManager.moveStateForward()
        #expect(dataManager.list(which: .priority).count == 0)
        #expect(compassCheckManager.state.rawValue == "pending")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "dueDate")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "review")
        compassCheckManager.moveStateForward()
        #expect(compassCheckManager.state.rawValue == "plan")
        compassCheckManager.moveStateForward()
        #expect(pref.daysOfCompassCheck == 43)
    }
}

extension Date: ExpressibleByExtendedGraphemeClusterLiteral {}
extension Date: ExpressibleByUnicodeScalarLiteral {}
extension Date: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: value) else {
            fatalError("Invalid ISO 8601 date format \(value)")
        }
        self = date
    }
}
