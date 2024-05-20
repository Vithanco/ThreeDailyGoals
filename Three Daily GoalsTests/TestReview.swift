//
//  TestReview.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 20/05/2024.
//

import XCTest
@testable import Three_Daily_Goals

final class TestReview: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNoStreak() throws {
        let store = TestPreferences()
        let pref = CloudPreferences(store: store)
        let model = dummyViewModel( preferences:  pref)
        
        XCTAssertEqual(pref.currentReviewInterval,getReviewInterval())
        
        pref.currentReviewInterval = DateInterval(start: getDate(daysPrior: 2), duration: Seconds.eightHours)
        XCTAssertFalse(pref.currentReviewInterval.contains(Date.now))
        
        model.reviewNow()
        XCTAssert(model.stateOfReview == .inform)
        model.moveStateForward()
        XCTAssertEqual(model.list(which: .priority).count, 1)
        XCTAssert(model.stateOfReview == .currentPriorities)
        model.moveStateForward()
        XCTAssertEqual(model.list(which: .priority).count, 0)
        XCTAssertEqual(model.stateOfReview, .pending)
        model.moveStateForward()
        XCTAssertEqual(model.stateOfReview,.dueDate)
        model.moveStateForward()
        XCTAssertEqual(model.stateOfReview, .review)
        model.moveStateForward()
        XCTAssertEqual(model.stateOfReview, .inform)
        XCTAssertEqual(pref.daysOfReview, 1)
        for t in model.items {
            t.dueDate = nil
        }
        XCTAssertTrue(model.dueDateSoon.isEmpty)
        
        XCTAssertFalse(model.showReviewDialog)
        model.reviewNow()
        
        XCTAssertTrue(model.showReviewDialog)
        XCTAssert(model.stateOfReview == .inform)
        
        XCTAssertTrue(model.dueDateSoon.isEmpty)
        XCTAssertEqual(model.list(which: .priority).count, 1)
        model.moveStateForward()
        
        XCTAssertTrue(model.dueDateSoon.isEmpty)
        XCTAssert(model.stateOfReview == .currentPriorities)
        model.moveStateForward()
        
        XCTAssertTrue(model.dueDateSoon.isEmpty)
        XCTAssertEqual(model.stateOfReview, .pending)
        XCTAssertTrue(model.dueDateSoon.isEmpty)
        model.moveStateForward()
        XCTAssertEqual(model.stateOfReview, .review)
        model.moveStateForward()
        XCTAssertEqual(model.stateOfReview, .inform)
        XCTAssertEqual(pref.daysOfReview, 1)
        XCTAssertFalse(model.showReviewDialog)
        
        model.reviewNow()
        XCTAssertTrue(model.showReviewDialog)
        XCTAssert(model.stateOfReview == .inform)
        XCTAssertEqual(model.list(which: .priority).count, 0)
        model.moveStateForward()
        XCTAssertEqual(model.stateOfReview, .pending)
        model.moveStateForward()
        XCTAssertEqual(model.stateOfReview, .review)
        model.moveStateForward()
        XCTAssertEqual(model.stateOfReview, .inform)
        XCTAssertEqual(pref.daysOfReview, 1)
    }
    
    func testIncreaseStreak() throws {
        let model = dummyViewModel()
        let pref = model.preferences
        
        XCTAssertEqual(pref.daysOfReview, 42)
        XCTAssertEqual(pref.currentReviewInterval,getReviewInterval())
        pref.lastReview = getDate(daysPrior: 1)
        
        model.reviewNow()
        XCTAssert(model.stateOfReview == .inform)
        model.moveStateForward()
        XCTAssert(model.stateOfReview == .currentPriorities)
        model.moveStateForward()
        XCTAssertEqual(model.stateOfReview, .pending)
        model.moveStateForward()
        XCTAssertEqual(model.stateOfReview,.dueDate)
        model.moveStateForward()
        XCTAssertEqual(model.stateOfReview, .review)
        model.moveStateForward()
        XCTAssertEqual(model.stateOfReview, .inform)
        XCTAssertEqual(pref.daysOfReview, 43)
        
        model.reviewNow()
        XCTAssert(model.stateOfReview == .inform)
        model.moveStateForward()
        XCTAssert(model.stateOfReview == .currentPriorities)
        model.moveStateForward()
        XCTAssertEqual(model.stateOfReview, .pending)
        model.moveStateForward()
        XCTAssertEqual(model.stateOfReview,.dueDate)
        model.moveStateForward()
        XCTAssertEqual(model.stateOfReview, .review)
        model.moveStateForward()
        XCTAssertEqual(model.stateOfReview, .inform)
        XCTAssertEqual(pref.daysOfReview, 43)
    }

}
