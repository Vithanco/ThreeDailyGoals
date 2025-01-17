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


    func testNoStreak() throws {
        let store = TestPreferences()
        let pref = CloudPreferences(store: store)
        let model = dummyViewModel( preferences:  pref)
        
        #expect(pref.currentReviewInterval == getReviewInterval())
        
        pref.currentReviewInterval = DateInterval(start: getDate(daysPrior: 2), duration: Seconds.eightHours)
        #expect(!pref.currentReviewInterval.contains(Date.now))
        
        model.reviewNow()
        #expect(model.stateOfReview == .inform)
        model.moveStateForward()
        #expect(model.list(which: .priority).count == 1)
        #expect(model.stateOfReview == .currentPriorities)
        model.moveStateForward()
        #expect(model.list(which: .priority).count == 0)
        #expect(model.stateOfReview == .pending)
        model.moveStateForward()
        #expect(model.stateOfReview == .dueDate)
        model.moveStateForward()
        #expect(model.stateOfReview == .review)
        model.moveStateForward()
        #expect(model.stateOfReview == .inform)
        #expect(pref.daysOfReview == 1)
        for t in model.items {
            t.dueDate = nil
        }
        #expect(model.dueDateSoon.isEmpty)
        
        #expect(!model.showReviewDialog)
        model.reviewNow()
        
        #expect(model.showReviewDialog)
        #expect(model.stateOfReview == .inform)
        
        #expect(model.dueDateSoon.isEmpty)
        #expect(model.list(which: .priority).count == 1)
        model.moveStateForward()
        
        #expect(model.dueDateSoon.isEmpty)
        #expect(model.stateOfReview == .currentPriorities)
        model.moveStateForward()
        
        #expect(model.dueDateSoon.isEmpty)
        #expect(model.stateOfReview == .pending)
        #expect(model.dueDateSoon.isEmpty)
        model.moveStateForward()
        #expect(model.stateOfReview == .review)
        model.moveStateForward()
        #expect(model.stateOfReview == .inform)
        #expect(pref.daysOfReview == 1)
        #expect(model.showReviewDialog)
        
        model.reviewNow()
        #expect(model.showReviewDialog)
        #expect(model.stateOfReview == .inform)
        #expect(model.list(which: .priority).count == 0)
        model.moveStateForward()
        #expect(model.stateOfReview == .pending)
        model.moveStateForward()
        #expect(model.stateOfReview == .review)
        model.moveStateForward()
        #expect(model.stateOfReview == .inform)
        #expect(pref.daysOfReview == 1)
    }
    
    @MainActor
    func testIncreaseStreak() throws {
        let model = dummyViewModel()
        let pref = model.preferences
        
        #expect(pref.daysOfReview == 42)
        #expect(pref.currentReviewInterval == getReviewInterval())
        pref.lastReview = getDate(daysPrior: 1)
        
        model.reviewNow()
        #expect(model.stateOfReview == .inform)
        model.moveStateForward()
        #expect(model.stateOfReview == .currentPriorities)
        model.moveStateForward()
        #expect(model.stateOfReview == .pending)
        model.moveStateForward()
        #expect(model.stateOfReview == .dueDate)
        model.moveStateForward()
        #expect(model.stateOfReview == .review)
        model.moveStateForward()
        #expect(model.stateOfReview == .inform)
        #expect(pref.daysOfReview == 43)
        
        model.reviewNow()
        #expect(model.stateOfReview == .inform)
        model.moveStateForward()
        #expect(model.stateOfReview == .currentPriorities)
        model.moveStateForward()
        #expect(model.stateOfReview == .pending)
        model.moveStateForward()
        #expect(model.stateOfReview == .dueDate)
        model.moveStateForward()
        #expect(model.stateOfReview == .review)
        model.moveStateForward()
        #expect(model.stateOfReview == .inform)
        #expect(pref.daysOfReview == 43)
    }
    
    @MainActor
    func testReviewInterval() throws {
        let model = dummyViewModel()
        let pref = model.preferences
        
        pref.currentReviewInterval = DateInterval(start: m24, end: now)
        pref.lastReview = m15
        #expect(model.didLastReviewHappenInCurrentReviewInterval())
        
        
        pref.lastReview = m25
        #expect(!model.didLastReviewHappenInCurrentReviewInterval())
        #expect(!pref.lastReview.isToday)
        
    }
    
    let now: Date = "2024-06-02T03:48:00Z"
    let m15: Date = "2024-06-01T13:48:00Z"
    let m24: Date = "2024-06-01T03:48:00Z"
    let m25: Date = "2024-06-01T02:48:00Z"
    
    
    @MainActor
    func testStreak() throws {
        let model = dummyViewModel()
        let pref = model.preferences
        
        pref.lastReview = m24
        pref.currentReviewInterval = getReviewInterval(forDate: m24)
        #expect (pref.didReviewToday)
        
        pref.currentReviewInterval = getReviewInterval()
        #expect (!pref.didReviewToday)
        
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
