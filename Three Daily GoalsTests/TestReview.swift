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
        let store = TestPreferences()
        let pref = CloudPreferences(store: store)
        let model = dummyViewModel(preferences: pref)
        pref.lastCompassCheck = Date(timeIntervalSinceNow: -Seconds.twoDays)

        model.compassCheckManager.startCompassCheckNow()
        #expect(model.compassCheckManager.state.rawValue == "inform")
        model.compassCheckManager.moveStateForward()
        #expect(model.dataManager.list(which: .priority).count == 1)
        #expect(model.compassCheckManager.state.rawValue == "currentPriorities")
        model.compassCheckManager.moveStateForward()
        #expect(model.dataManager.list(which: .priority).count == 0)
        #expect(model.compassCheckManager.state.rawValue == "pending")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "dueDate")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "review")
        model.compassCheckManager.moveStateForward()
        if OsRelated.currentOS == .macOS {
            #expect(model.compassCheckManager.state.rawValue == "plan")
            model.compassCheckManager.moveStateForward()
        }
        #expect(model.compassCheckManager.state.rawValue == "inform")
        #expect(pref.daysOfCompassCheck == 1)
        for t in model.dataManager.items {
            t.dueDate = nil
        }
        #expect(model.compassCheckManager.dueDateSoon.isEmpty)

        #expect(!model.uiState.showCompassCheckDialog)
        model.compassCheckManager.startCompassCheckNow()

        #expect(model.uiState.showCompassCheckDialog)
        #expect(model.compassCheckManager.state.rawValue == "inform")

        #expect(model.compassCheckManager.dueDateSoon.isEmpty)
        debugPrint(model.dataManager.list(which: .priority).map { $0.title })
        #expect(model.dataManager.list(which: .priority).count == 2)
        model.compassCheckManager.moveStateForward()

        #expect(model.compassCheckManager.dueDateSoon.isEmpty)
        #expect(model.compassCheckManager.state.rawValue == "currentPriorities")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "pending")

        #expect(model.compassCheckManager.state.rawValue == "pending")
        #expect(model.compassCheckManager.dueDateSoon.isEmpty)
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "review")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "plan")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "inform")
        #expect(pref.daysOfCompassCheck == 1)
        #expect(!model.uiState.showCompassCheckDialog)

        model.compassCheckManager.startCompassCheckNow()
        #expect(model.uiState.showCompassCheckDialog)
        #expect(model.compassCheckManager.state.rawValue == "inform")
        #expect(model.dataManager.list(which: .priority).count == 0)
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "pending")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "review")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "plan")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "inform")
        #expect(pref.daysOfCompassCheck == 1)
    }

    @MainActor
    @Test
    func testIncreaseStreak() throws {
        let model = dummyViewModel()
        let pref = model.preferences

        #expect(pref.daysOfCompassCheck == 42)
        pref.lastCompassCheck = getDate(daysPrior: 1)

        model.compassCheckManager.startCompassCheckNow()
        #expect(model.compassCheckManager.state.rawValue == "inform")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "currentPriorities")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "pending")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "dueDate")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "review")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "plan")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "inform")
        #expect(pref.daysOfCompassCheck == 43)

        model.compassCheckManager.startCompassCheckNow()
        #expect(model.compassCheckManager.state.rawValue == "inform")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "currentPriorities")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "pending")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "dueDate")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "review")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "plan")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "inform")
        #expect(pref.daysOfCompassCheck == 43)
    }

    @MainActor
    @Test
    func testReviewInterval() throws {
        let model = dummyViewModel()
        let pref = model.preferences

        pref.lastCompassCheck = getCompassCheckInterval().start.addingTimeInterval(1)
        #expect(model.preferences.didCompassCheckToday)

        // Set lastCompassCheck to a time outside the current compass check interval
        let currentInterval = getCompassCheckInterval()
        pref.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600) // 1 hour before interval
        #expect(!model.preferences.didCompassCheckToday)
        #expect(!pref.lastCompassCheck.isToday)
    }

    let now: Date = "2024-06-02T03:48:00Z"
    let m15: Date = "2024-06-01T13:48:00Z"
    let m24: Date = "2024-06-01T03:48:00Z"  //minus 24 hours
    let m25: Date = "2024-06-01T02:48:00Z"

    @MainActor
    @Test
    func testdidCompassCheckToday() throws {
        let model = dummyViewModel(preferences: dummyPreferences())
        let pref = model.preferences

        // Set lastCompassCheck to a time within the current compass check interval
        let currentInterval = getCompassCheckInterval()
        pref.lastCompassCheck = currentInterval.start.addingTimeInterval(1)
        #expect(pref.didCompassCheckToday)
        #expect(model.preferences.didCompassCheckToday)

    }

    @MainActor
    @Test
    func testReview() {
        let model = dummyViewModel(preferences: dummyPreferences())
        let pref = model.preferences

        // Set lastCompassCheck to a time outside the current compass check interval
        let currentInterval = getCompassCheckInterval()
        pref.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600) // 1 hour before interval
        #expect(!pref.didCompassCheckToday)

        #expect(pref.daysOfCompassCheck == 42)
        model.compassCheckManager.startCompassCheckNow()
        #expect(model.compassCheckManager.state.rawValue == "inform")
        model.compassCheckManager.moveStateForward()
        #expect(model.dataManager.list(which: .priority).count == 1)
        #expect(model.compassCheckManager.state.rawValue == "currentPriorities")
        model.compassCheckManager.moveStateForward()
        #expect(model.dataManager.list(which: .priority).count == 0)
        #expect(model.compassCheckManager.state.rawValue == "pending")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "dueDate")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "review")
        model.compassCheckManager.moveStateForward()
        #expect(model.compassCheckManager.state.rawValue == "plan")
        model.compassCheckManager.moveStateForward()
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
