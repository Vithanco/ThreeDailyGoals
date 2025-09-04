//
//  PreferencesTests.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 30/01/2024.
//

import Foundation
import Testing

@testable import Three_Daily_Goals

@Suite
struct PreferencesTests {

    @Test
    @MainActor
    func testDates() throws {
        let tester = TestPreferences()
        let preferences = CloudPreferences(store: tester, timeProvider: RealTimeProvider())
        let timeProvider = RealTimeProvider()
        var date = timeProvider.todayAt(hour: 23, min: 59)
        debugPrint("Date is : \(date.formatted())")
        #expect(timeProvider.component(.second, from: date) == 0)
        #expect(timeProvider.component(.minute, from: date) == 59)
        #expect(timeProvider.component(.hour, from: date) == 23)

        preferences.compassCheckTime = date
        #expect(preferences.compassCheckTime == date)
        #expect(tester.int(forKey: .compassCheckTimeHour) == 23)
        #expect(tester.int(forKey: .compassCheckTimeMinute) == 59)
        var newDate = preferences.compassCheckTime
        debugPrint(
            "Time is : \(stdOnlyTimeFormat.format(newDate)), date is: \(stdOnlyDateFormat.format(newDate))"
        )
        #expect(newDate > Date.now)
        #expect(newDate != timeProvider.today)
        #expect(newDate <= Date.now.addingTimeInterval(Seconds.fullDay))
        #expect(23 == timeProvider.hour(of: newDate))
        #expect(59 == timeProvider.minute(of: newDate))
        #expect(timeProvider.isToday(newDate) || timeProvider.isDateInTomorrow(newDate))

        date = timeProvider.todayAt(hour: 0, min: 1)
        preferences.compassCheckTime = date
        #expect(tester.int(forKey: .compassCheckTimeHour) == 0)
        #expect(tester.int(forKey: .compassCheckTimeMinute) == 1)
        newDate = preferences.nextCompassCheckTime
        debugPrint(
            "Time is : \(stdOnlyTimeFormat.format(newDate)), date is: \(stdOnlyDateFormat.format(newDate))"
        )
        #expect(newDate > Date.now)
        #expect(preferences.compassCheckTime < Date.now)
        #expect(newDate != timeProvider.today)
        #expect(newDate <= Date.now.addingTimeInterval(Seconds.fullDay))
        #expect(0 == timeProvider.component(.hour, from: newDate))
        #expect(1 == timeProvider.component(.minute, from: newDate))
        #expect(timeProvider.isToday(newDate) || timeProvider.isDateInTomorrow(newDate))

        date = Date.now
        preferences.lastCompassCheck = date
        newDate = preferences.nextCompassCheckTime
        debugPrint(
            "Time is : \(stdOnlyTimeFormat.format(newDate)), date is: \(stdOnlyDateFormat.format(newDate))"
        )
        #expect(newDate > Date.now)
        #expect(newDate != timeProvider.today)
        #expect(newDate <= Date.now.addingTimeInterval(Seconds.fullDay))
        #expect(timeProvider.isToday(newDate) || timeProvider.isDateInTomorrow(newDate))
    }

}
