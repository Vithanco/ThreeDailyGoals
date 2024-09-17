//
//  TestDailyReviewTime.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 06/02/2024.
//

import XCTest
@testable import Three_Daily_Goals

final class TestDailyReviewTime: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testToday()throws {
        let formatter = Date.FormatStyle(date: .numeric, time: .complete)
        XCTAssertTrue(Date.now.isToday)
        var date = todayAt(hour: 23, min: 59)
        XCTAssertTrue(date.isToday, "\(formatter.format(date))")
        date = date.addingTimeInterval( Seconds.fiveMin)
        XCTAssertFalse(date.isToday, "\(formatter.format(date))")
        date = todayAt(hour: 0, min: 1)
        XCTAssertTrue(date.isToday, "\(formatter.format(date))")
        date = date.addingTimeInterval(-1 * Seconds.fiveMin)
        XCTAssertFalse(date.isToday, "\(formatter.format(date))")
        
    }
    
    func testExample() throws {
        let tester = TestPreferences()
        let preferences = CloudPreferences(store: tester )
        let date = Calendar.current.date(from: DateComponents(hour: 15, minute: 08))!
        preferences.reviewTime = date;
        XCTAssertEqual(tester.inner.longLong(forKey: "test_reviewTimeHour"), 15)
        XCTAssertEqual(tester.inner.longLong(forKey: "test_reviewTimeMinute"),08)
        
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
