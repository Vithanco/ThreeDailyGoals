//
//  TestDailyReviewTime.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 06/02/2024.
//

import Foundation
import Testing

@testable import Three_Daily_Goals

@Suite
struct TestDailyCompassCheckTime {

    @Test
    func testToday() throws {
        let formatter = Date.FormatStyle(date: .numeric, time: .complete)
        let timeProvider = RealTimeProvider()
        #expect(timeProvider.isToday(Date.now))
        var date = timeProvider.todayAt(hour: 23, min: 59)
        #expect(timeProvider.isToday(date), "\(formatter.format(date))")
        date = date.addingTimeInterval(Seconds.fiveMin)
        #expect(!timeProvider.isToday(date), "\(formatter.format(date))")
        date = timeProvider.todayAt(hour: 0, min: 1)
        #expect(timeProvider.isToday(date), "\(formatter.format(date))")
        date = date.addingTimeInterval(-1 * Seconds.fiveMin)
        #expect(!timeProvider.isToday(date), "\(formatter.format(date))")

    }

    @Test
    @MainActor
    func testTime() throws {
        let tester = TestPreferences()
        let preferences = CloudPreferences(store: tester, timeProvider: RealTimeProvider())
        let timeProvider = RealTimeProvider()
        let date = timeProvider.date(from: DateComponents(hour: 15, minute: 08))!
        preferences.compassCheckTime = date
        #expect(tester.int(forKey: StorageKeys.compassCheckTimeHour) == 15)
        #expect(tester.int(forKey: StorageKeys.compassCheckTimeMinute) == 08)

    }

}
