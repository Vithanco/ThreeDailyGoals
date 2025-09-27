//
//  TestNotificationLogicSimple.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-07.
//

import Foundation
import Testing
@testable import Three_Daily_Goals
@testable import tdgCoreMain

@Suite
@MainActor
struct TestNotificationLogicSimple {
    
    @Test
    func testStreakReminderLogic_Streak2Days_Pending_ShouldSchedule() async throws {
        // Given: 2-day streak, CC pending, current time 10:00 AM
        let currentTime = createTime(hour: 10, minute: 0)
        let timeProvider = MockTimeProvider(fixedNow: currentTime)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider)
        let preferences = appComponents.preferences
        
        // Set up test state
        preferences.daysOfCompassCheck = 2
        // Set lastCompassCheck to be within the previous interval to maintain streak
        let currentInterval = timeProvider.getCompassCheckInterval()
        let previousIntervalStart = timeProvider.calendar.date(byAdding: .day, value: -1, to: currentInterval.start) ?? currentInterval.start
        preferences.lastCompassCheck = previousIntervalStart.addingTimeInterval(3600) // 1 hour after previous interval start
        preferences.notificationsEnabled = true // Enable notifications for testing
        
        // When: Check the conditions that would determine scheduling
        let shouldSchedule = preferences.daysOfCompassCheck >= 2 && !preferences.didCompassCheckToday
        
        // Then: Should schedule notification
        #expect(shouldSchedule, "2-day streak with pending CC should schedule notification")
        #expect(preferences.daysOfCompassCheck == 2, "Streak should be 2 days")
        #expect(!preferences.didCompassCheckToday, "CC should be pending")
    }
    
    @Test
    func testStreakReminderLogic_Streak1Day_Pending_ShouldNotSchedule() async throws {
        // Given: 1-day streak, CC pending, current time 10:00 AM
        let currentTime = createTime(hour: 10, minute: 0)
        let timeProvider = MockTimeProvider(fixedNow: currentTime)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider)
        let preferences = appComponents.preferences
        
        // Set up test state
        preferences.daysOfCompassCheck = 1
        // Set lastCompassCheck to be within the previous interval to maintain streak
        let currentInterval = timeProvider.getCompassCheckInterval()
        let previousIntervalStart = timeProvider.calendar.date(byAdding: .day, value: -1, to: currentInterval.start) ?? currentInterval.start
        preferences.lastCompassCheck = previousIntervalStart.addingTimeInterval(3600) // 1 hour after previous interval start
        preferences.notificationsEnabled = true // Enable notifications for testing
        
        // When: Check the conditions that would determine scheduling
        let shouldSchedule = preferences.daysOfCompassCheck >= 2 && !preferences.didCompassCheckToday
        
        // Then: Should NOT schedule notification
        #expect(!shouldSchedule, "1-day streak should not schedule notification")
        #expect(preferences.daysOfCompassCheck == 1, "Streak should be 1 day")
        #expect(!preferences.didCompassCheckToday, "CC should be pending")
    }
    
    @Test
    func testStreakReminderLogic_Streak2Days_DoneToday_ShouldNotSchedule() async throws {
        // Given: 2-day streak, CC done today, current time 10:00 AM
        let currentTime = createTime(hour: 10, minute: 0)
        let timeProvider = MockTimeProvider(fixedNow: currentTime)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider)
        let preferences = appComponents.preferences
        
        // Set up test state
        preferences.daysOfCompassCheck = 2
        preferences.lastCompassCheck = timeProvider.now // CC done today
        preferences.notificationsEnabled = true // Enable notifications for testing
        
        // When: Check the conditions that would determine scheduling
        let shouldSchedule = preferences.daysOfCompassCheck >= 2 && !preferences.didCompassCheckToday
        
        // Then: Should NOT schedule notification (CC not pending)
        #expect(!shouldSchedule, "2-day streak with CC done today should not schedule notification")
        #expect(preferences.daysOfCompassCheck == 2, "Streak should be 2 days")
        #expect(preferences.didCompassCheckToday, "CC should be done today")
    }
    
    @Test
    func testSystemNotificationLogic_CCPending_ShouldSchedule() async throws {
        // Given: CC pending, time set to 6:00 PM
        let currentTime = createTime(hour: 14, minute: 0)
        let timeProvider = MockTimeProvider(fixedNow: currentTime)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider)
        let preferences = appComponents.preferences
        
        // Set up test state
        // Set lastCompassCheck to be within the previous interval to maintain streak
        let currentInterval = timeProvider.getCompassCheckInterval()
        let previousIntervalStart = timeProvider.calendar.date(byAdding: .day, value: -1, to: currentInterval.start) ?? currentInterval.start
        preferences.lastCompassCheck = previousIntervalStart.addingTimeInterval(3600) // 1 hour after previous interval start
        preferences.compassCheckTime = createTime(hour: 18, minute: 0) // 6 PM
        preferences.notificationsEnabled = true // Enable notifications for testing
        
        // When: Check the conditions that would determine scheduling
        let shouldSchedule = !preferences.didCompassCheckToday
        
        // Then: Should schedule notification
        #expect(shouldSchedule, "CC pending should schedule system notification")
        #expect(!preferences.didCompassCheckToday, "CC should be pending")
    }
    
    @Test
    func testSystemNotificationLogic_CCDoneToday_ShouldNotSchedule() async throws {
        // Given: CC done today, time set to 6:00 PM
        let currentTime = createTime(hour: 14, minute: 0)
        let timeProvider = MockTimeProvider(fixedNow: currentTime)
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider)
        let preferences = appComponents.preferences
        
        // Set up test state
        preferences.lastCompassCheck = timeProvider.now // CC done today
        preferences.compassCheckTime = createTime(hour: 18, minute: 0) // 6 PM
        preferences.notificationsEnabled = true // Enable notifications for testing
        
        // When: Check the conditions that would determine scheduling
        let shouldSchedule = !preferences.didCompassCheckToday
        
        // Then: Should NOT schedule notification (CC not pending)
        #expect(!shouldSchedule, "CC done today should not schedule system notification")
        #expect(preferences.didCompassCheckToday, "CC should be done today")
    }
    
    // MARK: - Helper Methods
    
    private func createTime(hour: Int, minute: Int) -> Date {
        let realTimeProvider = RealTimeProvider()
        return realTimeProvider.date(from: DateComponents(
            year: 2025, month: 1, day: 15, 
            hour: hour, minute: minute, second: 0
        ))!
    }
}
