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
    
    init() {
        preferences = CloudPreferences(testData: true)
        // Reset to known state
        preferences.lastCompassCheck = Date.now
        preferences.daysOfCompassCheck = 0
        preferences.longestStreak = 0
    }
    
    // MARK: - Test isStreakBroken Logic
    
    @Test
    func testIsStreakBroken_WhenLastCheckIsToday_ReturnsFalse() throws {
        // Given: Last compass check was today
        preferences.lastCompassCheck = Date.now
        
        // When: Checking isStreakBroken
        // Then: Should return false because streak is active (check done today)
        #expect(!preferences.isStreakBroken, "isStreakBroken should be false when last check was today")
    }
    
    @Test
    func testIsStreakBroken_WhenLastCheckIsYesterday_ReturnsFalse() throws {
        // Given: Last compass check was yesterday (within last interval)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date.now)!
        preferences.lastCompassCheck = yesterday
        
        // When: Checking isStreakBroken
        let result = preferences.isStreakBroken
        
        // Then: Should return false because streak is active (check done yesterday)
        #expect(!result, "isStreakBroken should be false when last check was yesterday")
    }
    
    @Test
    func testIsStreakBroken_WhenLastCheckIsTwoDaysAgo_ReturnsTrue() throws {
        // Given: Last compass check was two days ago (outside both intervals)
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date.now)!
        preferences.lastCompassCheck = twoDaysAgo
        
        // When: Checking isStreakBroken
        let result = preferences.isStreakBroken
        
        // Then: Should return true because streak is broken (no recent checks)
        #expect(result, "isStreakBroken should be true when last check was two days ago")
    }
    
    @Test
    func testIsStreakBroken_WhenLastCheckIsInFuture_ReturnsTrue() throws {
        // Given: Last compass check is in the future (edge case)
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date.now)!
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
        let today = Date.now
        let beforeNoon = Calendar.current.date(bySettingHour: 11, minute: 59, second: 0, of: today)!
        preferences.lastCompassCheck = beforeNoon
        
        // When: Checking isStreakBroken
        let result = preferences.isStreakBroken
        
        // Then: Should return false because it's within today's interval (streak active)
        #expect(!result, "isStreakBroken should be false when last check was just before noon today")
    }
    
    @Test
    func testIsStreakBroken_WhenLastCheckIsJustBeforeNoonYesterday_ReturnsFalse() throws {
        // Given: Last compass check was just before noon yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date.now) ?? Date.now
        let beforeNoon = Calendar.current.date(bySettingHour: 11, minute: 59, second: 0, of: yesterday) ?? yesterday
        preferences.lastCompassCheck = beforeNoon
        
        // When: Checking isStreakBroken
        let result = preferences.isStreakBroken
        
        // Then: Should return false because it's within yesterday's interval (streak active)
        #expect(!result, "isStreakBroken should be false when last check was just before noon yesterday")
    }
    
    @Test
    func testIsStreakBroken_WhenLastCheckIsJustAfterNoonYesterday_ReturnsFalse() throws {
        // Given: Last compass check was just after noon yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date.now) ?? Date.now
        let afterNoon = Calendar.current.date(bySettingHour: 12, minute: 1, second: 0, of: yesterday) ?? yesterday
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
        let today = Date.now
        let midnight = Calendar.current.startOfDay(for: today)
        preferences.lastCompassCheck = midnight
        
        // When: Checking isStreakBroken
        let result = preferences.isStreakBroken
        
        // Then: Should return false because midnight is within today's interval (streak active)
        #expect(!result, "isStreakBroken should be false when last check was at midnight")
    }
    
    @Test
    func testIsStreakBroken_WhenLastCheckIsExactlyAt11_59PM_ReturnsFalse() throws {
        // Given: Last compass check was exactly at 11:59 PM
        let yesterday = getDate(daysPrior: 1)
        let elevenFiftyNine = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday) ?? yesterday
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
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date.now) ?? Date.now
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
        preferences.lastCompassCheck = Date.now
        
        // When: Calling isStreakBroken multiple times
        let startTime = Date()
        for _ in 0..<1000 {
            _ = preferences.isStreakBroken
        }
        let endTime = Date()
        
        // Then: Should complete within reasonable time (less than 1 second)
        let duration = endTime.timeIntervalSince(startTime)
        #expect(duration < 1.0, "isStreakBroken should complete 1000 calls in less than 1 second")
    }
}
