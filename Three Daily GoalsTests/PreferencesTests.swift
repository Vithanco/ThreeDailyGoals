//
//  PreferencesTests.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 30/01/2024.
//

import Testing
@testable import Three_Daily_Goals
import Foundation

@Suite
struct PreferencesTests {

    @Test
    func testDates() throws {
        let tester = TestPreferences()
        let preferences = CloudPreferences(store: tester )
        var date = todayAt(hour: 23, min: 59)
        debugPrint("Date is : \(date.formatted())")
        #expect(getCal().component(.second, from: date) == 0)
        #expect(getCal().component(.minute, from: date) == 59)
        #expect(getCal().component(.hour, from: date) == 23)
        
        preferences.reviewTime = date;
        #expect(preferences.reviewTime == date)
        #expect(tester.int(forKey: .reviewTimeHour) == 23)
        #expect(tester.int(forKey: .reviewTimeMinute) == 59)
        var newDate = preferences.reviewTime
        debugPrint("Time is : \(stdOnlyTimeFormat.format(newDate)), date is: \(stdOnlyDateFormat.format(newDate))")
        #expect(newDate > Date.now)
        #expect(newDate != Date.today)
        #expect (newDate <= Date.now.addingTimeInterval(Seconds.fullDay))
        #expect(23 == newDate.hour)
        #expect(59 == newDate.min)
        #expect(newDate.isToday || getCal().isDateInTomorrow(newDate))
        
        date = todayAt(hour: 0, min: 1)
        preferences.reviewTime = date;
        #expect(tester.int(forKey: .reviewTimeHour) == 0)
        #expect(tester.int(forKey: .reviewTimeMinute) == 1)
        newDate = preferences.nextReviewTime
        debugPrint("Time is : \(stdOnlyTimeFormat.format(newDate)), date is: \(stdOnlyDateFormat.format(newDate))")
        #expect(newDate > Date.now)
        #expect(preferences.reviewTime < Date.now)
        #expect(newDate != Date.today)
        #expect (newDate <= Date.now.addingTimeInterval(Seconds.fullDay))
        #expect(0 == getCal().component(.hour, from: newDate))
        #expect(1 == getCal().component(.minute, from: newDate))
        #expect(newDate.isToday || getCal().isDateInTomorrow(newDate))
        
        date = Date.now
        preferences.reviewTime = date;
        newDate = preferences.nextReviewTime
        debugPrint("Time is : \(stdOnlyTimeFormat.format(newDate)), date is: \(stdOnlyDateFormat.format(newDate))")
        #expect(newDate > Date.now)
        #expect(newDate != Date.today)
        #expect (newDate <= Date.now.addingTimeInterval(Seconds.fullDay))
        #expect(newDate.isToday || getCal().isDateInTomorrow(newDate))
        
        var dateInterval = DateInterval(start:  getCal().date(from: DateComponents(hour: 13, minute: 13))!, duration: Seconds.eightHours)
        preferences.currentReviewInterval = dateInterval
        
        var returned = preferences.currentReviewInterval
        #expect(dateInterval.start == returned.start)
        #expect(dateInterval.end == returned.end)
    }

    
}
