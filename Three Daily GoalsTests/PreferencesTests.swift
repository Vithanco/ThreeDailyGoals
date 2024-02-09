//
//  PreferencesTests.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 30/01/2024.
//

import XCTest
@testable import Three_Daily_Goals



final class PreferencesTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDates() throws {
        var tester = TestPreferences()
        var preferences = CloudPreferences(store: tester )
        var date = Calendar.current.date(from: DateComponents(hour: 23, minute: 59))!
        preferences.reviewTime = date;
        XCTAssertEqual(tester.inner.longLong(forKey: "test_reviewTimeHour"), 23)
        XCTAssertEqual(tester.inner.longLong(forKey: "test_reviewTimeMinute"),59)
        var newDate = preferences.reviewTime
        debugPrint("Time is : \(stdOnlyTimeFormat.format(newDate)), date is: \(stdOnlyDateFormat.format(newDate))")
        XCTAssertTrue(newDate > Date.now)
        XCTAssertNotEqual(newDate, Date.today)
        XCTAssertTrue (newDate <= Date.now.addingTimeInterval(Seconds.fullDay))
        XCTAssertEqual(23, Calendar.current.component(.hour, from: newDate))
        XCTAssertEqual(59, Calendar.current.component(.minute, from: newDate))
        XCTAssertTrue(newDate.isToday || Calendar.current.isDateInTomorrow(newDate))
        
        date = Calendar.current.date(from: DateComponents(hour: 0, minute: 1))!
        preferences.reviewTime = date;
        XCTAssertEqual(tester.inner.longLong(forKey: "test_reviewTimeHour"),0)
        XCTAssertEqual(tester.inner.longLong(forKey: "test_reviewTimeMinute"),1)
        newDate = preferences.nextReviewTime
        debugPrint("Time is : \(stdOnlyTimeFormat.format(newDate)), date is: \(stdOnlyDateFormat.format(newDate))")
        XCTAssertTrue(newDate > Date.now)
        XCTAssertTrue(preferences.reviewTime < Date.now)
        XCTAssertNotEqual(newDate, Date.today)
        XCTAssertTrue (newDate <= Date.now.addingTimeInterval(Seconds.fullDay))
        XCTAssertEqual(0, Calendar.current.component(.hour, from: newDate))
        XCTAssertEqual(1, Calendar.current.component(.minute, from: newDate))
        XCTAssertTrue(newDate.isToday || Calendar.current.isDateInTomorrow(newDate))
        
        date = Date.now
        preferences.reviewTime = date;
        newDate = preferences.nextReviewTime
        debugPrint("Time is : \(stdOnlyTimeFormat.format(newDate)), date is: \(stdOnlyDateFormat.format(newDate))")
        XCTAssertTrue(newDate > Date.now)
        XCTAssertNotEqual(newDate, Date.today)
        XCTAssertTrue (newDate <= Date.now.addingTimeInterval(Seconds.fullDay))
        XCTAssertTrue(newDate.isToday || Calendar.current.isDateInTomorrow(newDate))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
