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

        model.startCompassCheckNow()
        #expect(model.stateOfCompassCheck == .inform)
        model.moveStateForward()
        #expect(model.list(which: .priority).count == 1)
        #expect(model.stateOfCompassCheck == .currentPriorities)
        model.moveStateForward()
        #expect(model.list(which: .priority).count == 0)
        #expect(model.stateOfCompassCheck == .pending)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .dueDate)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .review)
        model.moveStateForward()
        if model.os == .macOS {
            #expect(model.stateOfCompassCheck == .plan)
            model.moveStateForward()
        }
        #expect(model.stateOfCompassCheck == .inform)
        #expect(pref.daysOfCompassCheck == 1)
        for t in model.items {
            t.dueDate = nil
        }
        #expect(model.dueDateSoon.isEmpty)

        #expect(!model.showCompassCheckDialog)
        model.startCompassCheckNow()

        #expect(model.showCompassCheckDialog)
        #expect(model.stateOfCompassCheck == .inform)

        #expect(model.dueDateSoon.isEmpty)
        debugPrint(model.list(which: .priority).map { $0.title })
        #expect(model.list(which: .priority).count == 2)
        model.moveStateForward()

        #expect(model.dueDateSoon.isEmpty)
        #expect(model.stateOfCompassCheck == .currentPriorities)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .pending)

        #expect(model.stateOfCompassCheck == .pending)
        #expect(model.dueDateSoon.isEmpty)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .review)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .plan)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .inform)
        #expect(pref.daysOfCompassCheck == 1)
        #expect(!model.showCompassCheckDialog)

        model.startCompassCheckNow()
        #expect(model.showCompassCheckDialog)
        #expect(model.stateOfCompassCheck == .inform)
        #expect(model.list(which: .priority).count == 0)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .pending)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .review)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .plan)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .inform)
        #expect(pref.daysOfCompassCheck == 1)
    }

    @MainActor
    @Test
    func testIncreaseStreak() throws {
        let model = dummyViewModel()
        let pref = model.preferences

        #expect(pref.daysOfCompassCheck == 42)
        pref.lastCompassCheck = getDate(daysPrior: 1)

        model.startCompassCheckNow()
        #expect(model.stateOfCompassCheck == .inform)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .currentPriorities)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .pending)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .dueDate)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .review)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .plan)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .inform)
        #expect(pref.daysOfCompassCheck == 43)

        model.startCompassCheckNow()
        #expect(model.stateOfCompassCheck == .inform)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .currentPriorities)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .pending)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .dueDate)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .review)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .plan)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .inform)
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
        model.startCompassCheckNow()
        #expect(model.stateOfCompassCheck == .inform)
        model.moveStateForward()
        #expect(model.list(which: .priority).count == 1)
        #expect(model.stateOfCompassCheck == .currentPriorities)
        model.moveStateForward()
        #expect(model.list(which: .priority).count == 0)
        #expect(model.stateOfCompassCheck == .pending)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .dueDate)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .review)
        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .plan)
        model.moveStateForward()
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
