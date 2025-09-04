//
//  TestIsStreakBroken.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 2025-01-07.
//

import Foundation
import Testing
@testable import Three_Daily_Goals

@Suite
@MainActor
struct TestIsStreakBroken {
    
    var preferences: CloudPreferences!
    var timeProvider: MockTimeProvider!
    
    init() {
        // Create a mock time provider with a fixed time (10:00 AM) for deterministic tests
        let realTimeProvider = RealTimeProvider()
        let fixedDate = realTimeProvider.date(from: DateComponents(year: 2025, month: 1, day: 15, hour: 10, minute: 0, second: 0))!
        timeProvider = MockTimeProvider(fixedNow: fixedDate)
        
        preferences = CloudPreferences(testData: true, timeProvider: timeProvider)
        // Reset to known state
        preferences.lastCompassCheck = timeProvider.now
        preferences.daysOfCompassCheck = 0
        preferences.longestStreak = 0
    }
    
    // MARK: - Test isStreakBroken Logic
    
    @Test
    func testIsStreakBroken_WhenLastCheckIsToday_ReturnsFalse() throws {
        // Given: Last compass check was today
        preferences.lastCompassCheck = timeProvider.now
        
        // When: Checking isStreakBroken
        // Then: Should return false because streak is active (check done today)
        #expect(!preferences.isStreakBroken, "isStreakBroken should be false when last check was today")
    }
    
    @Test
    func testIsStreakBroken_WhenLastCheckIsYesterday_ReturnsFalse() throws {
        // Given: Last compass check was yesterday (within last interval)
        let yesterday = timeProvider.getDate(daysPrior: 1)
        preferences.lastCompassCheck = yesterday
        
        // When: Checking isStreakBroken
        let result = preferences.isStreakBroken
        
        // Then: Should return false because streak is active (check done yesterday)
        #expect(!result, "isStreakBroken should be false when last check was yesterday")
    }
    
    @Test
    func testIsStreakBroken_WhenLastCheckIsTwoDaysAgo_ReturnsTrue() throws {
        // Given: Last compass check was two days ago (outside both intervals)
        let twoDaysAgo = timeProvider.getDate(daysPrior: 2)
        preferences.lastCompassCheck = twoDaysAgo
        
        // When: Checking isStreakBroken
        let result = preferences.isStreakBroken
        
        // Then: Should return true because streak is broken (no recent checks)
        #expect(result, "isStreakBroken should be true when last check was two days ago")
    }
    
    @Test
    func testIsStreakBroken_WhenLastCheckIsInFuture_ReturnsTrue() throws {
        // Given: Last compass check is in the future (edge case)
        let futureDate = timeProvider.getDate(inDays: 1)
        preferences.lastCompassCheck = futureDate
        
        // When: Checking isStreakBroken
        let result = preferences.isStreakBroken
        
        // Then: Should return true because future dates are outside intervals (streak broken)
        #expect(result, "isStreakBroken should be true when last check is in the future")
    }
    
    // MARK: - Test Edge Cases Around Noon Boundary
    
    @Test
    func testIsStreakBroken_WhenLastCheckIsJustBeforeNoonToday_ReturnsFalse() throws {
        // Given: Last compass check was just before noon today
        let today = timeProvider.now
        let beforeNoon = timeProvider.calendar.date(bySettingHour: 11, minute: 59, second: 0, of: today)!
        preferences.lastCompassCheck = beforeNoon
        
        // When: Checking isStreakBroken
        let result = preferences.isStreakBroken
        
        // Then: Should return false because it's within today's interval (streak active)
        #expect(!result, "isStreakBroken should be false when last check was just before noon today")
    }
    
    @Test
    func testIsStreakBroken_WhenLastCheckIsJustBeforeNoonYesterday_ReturnsFalse() throws {
        // Given: Last compass check was just before noon yesterday
        let yesterday = timeProvider.getDate(daysPrior: 1)
        let beforeNoon = timeProvider.calendar.date(bySettingHour: 11, minute: 59, second: 0, of: yesterday)!
        preferences.lastCompassCheck = beforeNoon
        
        // When: Checking isStreakBroken
        let result = preferences.isStreakBroken
        
        // Then: Should return false because it's within yesterday's interval (streak active)
        #expect(!result, "isStreakBroken should be false when last check was just before noon yesterday")
    }
    
    @Test
    func testIsStreakBroken_WhenLastCheckIsJustAfterNoonYesterday_ReturnsFalse() throws {
        // Given: Last compass check was just after noon yesterday
        let yesterday = timeProvider.getDate(daysPrior: 1)
        let afterNoon = timeProvider.calendar.date(bySettingHour: 12, minute: 1, second: 0, of: yesterday)!
        preferences.lastCompassCheck = afterNoon
        
        // When: Checking isStreakBroken
        let result = preferences.isStreakBroken
        
        // Then: Should return false because it's within yesterday's interval (streak active)
        #expect(!result, "isStreakBroken should be false when last check was just after noon yesterday")
    }
    
    // MARK: - Test Boundary Conditions
    
    @Test
    func testIsStreakBroken_WhenLastCheckIsExactlyAtMidnight_ReturnsFalse() throws {
        // Given: Last compass check was exactly at midnight (start of day)
        let today = timeProvider.now
        let midnight = timeProvider.calendar.startOfDay(for: today)
        preferences.lastCompassCheck = midnight
        
        // When: Checking isStreakBroken
        let result = preferences.isStreakBroken
        
        // Then: Should return false because midnight is within today's interval (streak active)
        #expect(!result, "isStreakBroken should be false when last check was at midnight")
    }
    
    @Test
    func testIsStreakBroken_WhenLastCheckIsExactlyAt11_59PM_ReturnsFalse() throws {
        // Given: Last compass check was exactly at 11:59 PM
        let yesterday = timeProvider.getDate(daysPrior: 1)
        let elevenFiftyNine = timeProvider.calendar.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday)!
        preferences.lastCompassCheck = elevenFiftyNine
        
        // When: Checking isStreakBroken
        let result = preferences.isStreakBroken
        
        // Then: Should return false because 11:59 PM is within today's interval (streak active)
        #expect(!result, "isStreakBroken should be false when last check was at 11:59 PM")
    }
    
    // MARK: - Test Integration with Compass Check Manager
    
    @Test
    func testIsStreakBroken_AfterCompassCheckManagerResetsStreak_ReturnsTrue() throws {
        // Given: A broken streak scenario
        let twoDaysAgo = timeProvider.getDate(daysPrior: 2)
        preferences.lastCompassCheck = twoDaysAgo
        preferences.daysOfCompassCheck = 5 // Previous streak
        
        // Verify streak is initially broken
        #expect(preferences.isStreakBroken, "Streak should be broken initially")
        
        // When: Simulating compass check manager resetting streak
        preferences.daysOfCompassCheck = 0
        
        // Then: isStreakBroken should still reflect the actual state (streak still broken)
        #expect(preferences.isStreakBroken, "isStreakBroken should be true after streak reset")
    }
    
    // MARK: - Test Performance
    
    @Test
    func testIsStreakBroken_Performance() throws {
        // Given: A preferences object with last check set
        preferences.lastCompassCheck = timeProvider.now
        
        // When: Calling isStreakBroken multiple times
        let startTime = timeProvider.now
        for _ in 0..<1000 {
            _ = preferences.isStreakBroken
        }
        let endTime = timeProvider.now
        
        // Then: Should complete within reasonable time (less than 1 second)
        let duration = endTime.timeIntervalSince(startTime)
        #expect(duration < 1.0, "isStreakBroken should complete 1000 calls in less than 1 second")
    }
    

    
    // MARK: - Test Afternoon Time Scenarios (isStreakActive)
    
    @Test
    func testIsStreakActive_AfternoonTime_WhenLastCheckIsTodayMorning_ReturnsTrue() throws {
        // Given: Current time is afternoon (2:00 PM), last check was this morning
        let realTimeProvider = RealTimeProvider()
        let afternoonTimeProvider = MockTimeProvider(fixedNow: realTimeProvider.date(from: DateComponents(year: 2025, month: 1, day: 15, hour: 14, minute: 0, second: 0))!)
        let afternoonPreferences = CloudPreferences(testData: true, timeProvider: afternoonTimeProvider)
        
        // Last check was this morning at 9:00 AM
        let thisMorning = afternoonTimeProvider.calendar.date(bySettingHour: 9, minute: 0, second: 0, of: afternoonTimeProvider.now)!
        afternoonPreferences.lastCompassCheck = thisMorning
        
        // When: Checking isStreakActive in the afternoon
        let result = afternoonPreferences.isStreakActive
        

        
        // Then: Should return true because check was done this morning, which is within the 
        // previous interval (yesterday noon to today noon), so streak is active
        #expect(result, "isStreakActive should be true when last check was this morning, since it's within the previous interval")
    }
    
    @Test
    func testIsStreakActive_AfternoonTime_WhenLastCheckIsYesterdayAfternoon_ReturnsTrue() throws {
        // Given: Current time is afternoon (2:00 PM), last check was yesterday afternoon
        let realTimeProvider = RealTimeProvider()
        let afternoonTimeProvider = MockTimeProvider(fixedNow: realTimeProvider.date(from: DateComponents(year: 2025, month: 1, day: 15, hour: 14, minute: 0, second: 0))!)
        let afternoonPreferences = CloudPreferences(testData: true, timeProvider: afternoonTimeProvider)
        
        // Last check was yesterday at 3:00 PM
        let yesterday = afternoonTimeProvider.getDate(daysPrior: 1)
        let yesterdayAfternoon = afternoonTimeProvider.calendar.date(bySettingHour: 15, minute: 0, second: 0, of: yesterday)!
        afternoonPreferences.lastCompassCheck = yesterdayAfternoon
        
        // When: Checking isStreakActive in the afternoon
        let result = afternoonPreferences.isStreakActive
        
        // Then: Should return true because check was done yesterday (streak active)
        #expect(result, "isStreakActive should be true when last check was yesterday afternoon, even when checking in afternoon")
    }
    
    @Test
    func testIsStreakActive_AfternoonTime_WhenLastCheckIsTwoDaysAgo_ReturnsFalse() throws {
        // Given: Current time is afternoon (2:00 PM), last check was two days ago
        let realTimeProvider = RealTimeProvider()
        let afternoonTimeProvider = MockTimeProvider(fixedNow: realTimeProvider.date(from: DateComponents(year: 2025, month: 1, day: 15, hour: 14, minute: 0, second: 0))!)
        let afternoonPreferences = CloudPreferences(testData: true, timeProvider: afternoonTimeProvider)
        
        // Last check was two days ago at 10:00 AM
        let twoDaysAgo = afternoonTimeProvider.getDate(daysPrior: 2)
        let twoDaysAgoMorning = afternoonTimeProvider.calendar.date(bySettingHour: 10, minute: 0, second: 0, of: twoDaysAgo)!
        afternoonPreferences.lastCompassCheck = twoDaysAgoMorning
        
        // When: Checking isStreakActive in the afternoon
        let result = afternoonPreferences.isStreakActive
        
        // Then: Should return false because check was too long ago (streak broken)
        #expect(!result, "isStreakActive should be false when last check was two days ago, even when checking in afternoon")
    }
    
    @Test
    func testIsStreakActive_AfternoonTime_WhenLastCheckIsJustBeforeNoonToday_ReturnsTrue() throws {
        // Given: Current time is afternoon (2:00 PM), last check was just before noon today
        let realTimeProvider = RealTimeProvider()
        let afternoonTimeProvider = MockTimeProvider(fixedNow: realTimeProvider.date(from: DateComponents(year: 2025, month: 1, day: 15, hour: 14, minute: 0, second: 0))!)
        let afternoonPreferences = CloudPreferences(testData: true, timeProvider: afternoonTimeProvider)
        
        // Last check was just before noon today (11:59 AM)
        let today = afternoonTimeProvider.now
        let justBeforeNoon = afternoonTimeProvider.calendar.date(bySettingHour: 11, minute: 59, second: 0, of: today)!
        afternoonPreferences.lastCompassCheck = justBeforeNoon
        
        // When: Checking isStreakActive in the afternoon
        let result = afternoonPreferences.isStreakActive
        
        // Then: Should return true because check was done today (streak active)
        #expect(result, "isStreakActive should be true when last check was just before noon today, even when checking in afternoon")
    }
    
    @Test
    func testIsStreakActive_AfternoonTime_WhenLastCheckIsExactlyAtNoonToday_ReturnsTrue() throws {
        // Given: Current time is afternoon (2:00 PM), last check was exactly at noon today
        let realTimeProvider = RealTimeProvider()
        let afternoonTimeProvider = MockTimeProvider(fixedNow: realTimeProvider.date(from: DateComponents(year: 2025, month: 1, day: 15, hour: 14, minute: 0, second: 0))!)
        let afternoonPreferences = CloudPreferences(testData: true, timeProvider: afternoonTimeProvider)
        
        // Last check was exactly at noon today (12:00 PM)
        let today = afternoonTimeProvider.now
        let exactlyNoon = afternoonTimeProvider.calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!
        afternoonPreferences.lastCompassCheck = exactlyNoon
        
        // When: Checking isStreakActive in the afternoon
        let result = afternoonPreferences.isStreakActive
        
        // Then: Should return true because check was done today (streak active)
        #expect(result, "isStreakActive should be true when last check was exactly at noon today, even when checking in afternoon")
    }
    
    @Test
    func testIsStreakActive_AfternoonTime_WhenLastCheckIsJustAfterNoonToday_ReturnsTrue() throws {
        // Given: Current time is afternoon (2:00 PM), last check was just after noon today
        let realTimeProvider = RealTimeProvider()
        let afternoonTimeProvider = MockTimeProvider(fixedNow: realTimeProvider.date(from: DateComponents(year: 2025, month: 1, day: 15, hour: 14, minute: 0, second: 0))!)
        let afternoonPreferences = CloudPreferences(testData: true, timeProvider: afternoonTimeProvider)
        
        // Last check was just after noon today (12:01 PM)
        let today = afternoonTimeProvider.now
        let justAfterNoon = afternoonTimeProvider.calendar.date(bySettingHour: 12, minute: 1, second: 0, of: today)!
        afternoonPreferences.lastCompassCheck = justAfterNoon
        
        // When: Checking isStreakActive in the afternoon
        let result = afternoonPreferences.isStreakActive
        
        // Then: Should return true because check was done today (streak active)
        #expect(result, "isStreakActive should be true when last check was just after noon today, even when checking in afternoon")
    }
    
    @Test
    func testIsStreakActive_AfternoonTime_WhenLastCheckIsYesterdayMorning_ReturnsFalse() throws {
        // Given: Current time is afternoon (2:00 PM), last check was yesterday morning
        let realTimeProvider = RealTimeProvider()
        let afternoonTimeProvider = MockTimeProvider(fixedNow: realTimeProvider.date(from: DateComponents(year: 2025, month: 1, day: 15, hour: 14, minute: 0, second: 0))!)
        let afternoonPreferences = CloudPreferences(testData: true, timeProvider: afternoonTimeProvider)
        
        // Last check was yesterday morning at 8:00 AM
        let yesterday = afternoonTimeProvider.getDate(daysPrior: 1)
        let yesterdayMorning = afternoonTimeProvider.calendar.date(bySettingHour: 8, minute: 0, second: 0, of: yesterday)!
        afternoonPreferences.lastCompassCheck = yesterdayMorning
        
        // When: Checking isStreakActive in the afternoon
        let result = afternoonPreferences.isStreakActive
        
        // Then: Should return false because check was done yesterday morning (8:00 AM), 
        // which is BEFORE the previous interval (yesterday noon to today noon), so streak is broken
        #expect(!result, "isStreakActive should be false when last check was yesterday morning, since it's before the previous interval")
    }
    
    @Test
    func testIsStreakActive_AfternoonTime_WhenLastCheckIsYesterdayEvening_ReturnsTrue() throws {
        // Given: Current time is afternoon (2:00 PM), last check was yesterday evening
        let realTimeProvider = RealTimeProvider()
        let afternoonTimeProvider = MockTimeProvider(fixedNow: realTimeProvider.date(from: DateComponents(year: 2025, month: 1, day: 15, hour: 14, minute: 0, second: 0))!)
        let afternoonPreferences = CloudPreferences(testData: true, timeProvider: afternoonTimeProvider)
        
        // Last check was yesterday evening at 8:00 PM
        let yesterday = afternoonTimeProvider.getDate(daysPrior: 1)
        let yesterdayEvening = afternoonTimeProvider.calendar.date(bySettingHour: 20, minute: 0, second: 0, of: yesterday)!
        afternoonPreferences.lastCompassCheck = yesterdayEvening
        
        // When: Checking isStreakActive in the afternoon
        let result = afternoonPreferences.isStreakActive
        
        // Then: Should return true because check was done yesterday (streak active)
        #expect(result, "isStreakActive should be true when last check was yesterday evening, even when checking in afternoon")
    }
}
