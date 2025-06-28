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
        let model = dummyViewModel( preferences:  pref)
        
        #expect(pref.currentCompassCheckInterval == getCompassCheckInterval())
        
        pref.currentCompassCheckInterval = DateInterval(start: getDate(daysPrior: 2), duration: Seconds.eightHours)
        #expect(!pref.currentCompassCheckInterval.contains(Date.now))
        
        model.compassCheckNow()
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
        #expect(model.stateOfCompassCheck == .inform)
        #expect(pref.daysOfCompassCheck == 1)
        for t in model.items {
            t.dueDate = nil
        }
        #expect(model.dueDateSoon.isEmpty)
        
        #expect(!model.showCompassCheckDialog)
        model.compassCheckNow()
        
        #expect(model.showCompassCheckDialog)
        #expect(model.stateOfCompassCheck == .inform)
        
        #expect(model.dueDateSoon.isEmpty)
        debugPrint(model.list(which: .priority).map{$0.title})
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
        
        model.compassCheckNow()
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
        #expect(pref.currentCompassCheckInterval == getCompassCheckInterval())
        pref.lastCompassCheck = getDate(daysPrior: 1)
        
        model.compassCheckNow()
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
        
        model.compassCheckNow()
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
        
        pref.currentCompassCheckInterval = DateInterval(start: m24, end: now)
        pref.lastCompassCheck = m15
        #expect(model.didLastCompassCheckHappenInCurrentCompassCheckInterval())
        
        pref.lastCompassCheck = m25
        #expect(!model.didLastCompassCheckHappenInCurrentCompassCheckInterval())
        #expect(!pref.lastCompassCheck.isToday)
    }
    
    let now: Date = "2024-06-02T03:48:00Z"
    let m15: Date = "2024-06-01T13:48:00Z"
    let m24: Date = "2024-06-01T03:48:00Z"
    let m25: Date = "2024-06-01T02:48:00Z"
    
    @MainActor
    @Test
    func testStreak() throws {
        let model = dummyViewModel()
        let pref = model.preferences
        
        pref.lastCompassCheck = m24
        pref.currentCompassCheckInterval = getCompassCheckInterval(forDate: m24)
        #expect (pref.didCompassCheckToday)
        
        pref.currentCompassCheckInterval = getCompassCheckInterval()
        #expect (!pref.didCompassCheckToday)
        
    }
}

extension Date: ExpressibleByExtendedGraphemeClusterLiteral {}
extension Date:  ExpressibleByUnicodeScalarLiteral {}
extension Date:  ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: value) else {
            fatalError("Invalid ISO 8601 date format \(value)")
        }
        self = date
    }
}
