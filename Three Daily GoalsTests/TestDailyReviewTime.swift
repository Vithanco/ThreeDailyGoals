//
//  TestDailyReviewTime.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 06/02/2024.
//

import Testing
@testable import Three_Daily_Goals
import Foundation

@Suite
struct TestDailyReviewTime {

    @Test
    func testToday()throws {
        let formatter = Date.FormatStyle(date: .numeric, time: .complete)
        #expect(Date.now.isToday)
        var date = todayAt(hour: 23, min: 59)
        #expect(date.isToday, "\(formatter.format(date))")
        date = date.addingTimeInterval( Seconds.fiveMin)
        #expect(!date.isToday, "\(formatter.format(date))")
        date = todayAt(hour: 0, min: 1)
        #expect(date.isToday, "\(formatter.format(date))")
        date = date.addingTimeInterval(-1 * Seconds.fiveMin)
        #expect(!date.isToday, "\(formatter.format(date))")
        
    }
    
    @Test
    func testTime() throws {
        let tester = TestPreferences()
        let preferences = CloudPreferences(store: tester )
        let date = Calendar.current.date(from: DateComponents(hour: 15, minute: 08))!
        preferences.reviewTime = date;
        #expect(tester.inner.longLong(forKey: "test_reviewTimeHour") == 15)
        #expect(tester.inner.longLong(forKey: "test_reviewTimeMinute") == 08)
    
    }

}
