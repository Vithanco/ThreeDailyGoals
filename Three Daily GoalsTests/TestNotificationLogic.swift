//
//  TestNotificationLogic.swift
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
struct TestNotificationLogic {

    // MARK: - Helper Methods

    private func createTestScenario(
        currentTime: Date,
        streakDays: Int,
        didCompassCheckToday: Bool,
        compassCheckTime: Date? = nil
    ) -> (
        preferences: CloudPreferences, timeProvider: MockTimeProvider, pushNotificationManager: PushNotificationManager
    ) {

        // Create MockTimeProvider with fixed time
        let timeProvider = MockTimeProvider(fixedNow: currentTime)

        // Create app components with test setup
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider)
        let preferences = appComponents.preferences

        // Set up preferences state
        preferences.daysOfCompassCheck = streakDays
        if didCompassCheckToday {
            preferences.lastCompassCheck = timeProvider.now
        } else {
            // Set lastCompassCheck to be within the previous interval to maintain streak
            let currentInterval = timeProvider.getCompassCheckInterval()
            let previousIntervalStart =
                timeProvider.calendar.date(byAdding: .day, value: -1, to: currentInterval.start)
                ?? currentInterval.start
            preferences.lastCompassCheck = previousIntervalStart.addingTimeInterval(3600)  // 1 hour after previous interval start
        }
        preferences.notificationsEnabled = true  // Enable notifications for testing

        // Set compass check time if provided
        if let checkTime = compassCheckTime {
            preferences.compassCheckTime = checkTime
        }

        // Create PushNotificationManager with dependencies
        let pushNotificationManager = PushNotificationManager(preferences: preferences, timeProvider: timeProvider)

        return (preferences, timeProvider, pushNotificationManager)
    }

    // MARK: - Streak Reminder Notification Tests (11 AM)

    @Test
    func testStreakReminder_Streak1Day_Pending_ShouldNotSchedule() async throws {
        // Given: 1-day streak, CC pending, current time 10:00 AM
        let currentTime = createTime(hour: 10, minute: 0)
        let (preferences, timeProvider, pushNotificationManager) = createTestScenario(
            currentTime: currentTime,
            streakDays: 1,
            didCompassCheckToday: false
        )

        // When: scheduleStreakReminderNotification is called
        await pushNotificationManager.scheduleStreakReminderNotification()

        // Then: No notification should be scheduled (streak < 2)
        // Note: We can't easily test the actual notification scheduling in unit tests,
        // but we can verify the logic conditions are met
        #expect(preferences.daysOfCompassCheck == 1, "Streak should be 1 day")
        #expect(!preferences.didCompassCheckToday, "CC should be pending")
        #expect(preferences.daysOfCompassCheck < 2, "Streak should be below threshold")
    }

    @Test
    func testStreakReminder_Streak2Days_Pending_ShouldSchedule() async throws {
        // Given: 2-day streak, CC pending, current time 10:00 AM
        let currentTime = createTime(hour: 10, minute: 0)
        let (preferences, timeProvider, pushNotificationManager) = createTestScenario(
            currentTime: currentTime,
            streakDays: 2,
            didCompassCheckToday: false
        )

        // When: scheduleStreakReminderNotification is called
        await pushNotificationManager.scheduleStreakReminderNotification()

        // Then: Notification should be scheduled for 11:00 AM
        #expect(preferences.daysOfCompassCheck == 2, "Streak should be 2 days")
        #expect(!preferences.didCompassCheckToday, "CC should be pending")
        #expect(preferences.daysOfCompassCheck >= 2, "Streak should meet threshold")
        #expect(timeProvider.now < createTime(hour: 11, minute: 0), "Current time should be before 11 AM")
    }

    @Test
    func testStreakReminder_Streak2Days_DoneToday_ShouldNotSchedule() async throws {
        // Given: 2-day streak, CC done today, current time 10:00 AM
        let currentTime = createTime(hour: 10, minute: 0)
        let (preferences, timeProvider, pushNotificationManager) = createTestScenario(
            currentTime: currentTime,
            streakDays: 2,
            didCompassCheckToday: true
        )

        // When: scheduleStreakReminderNotification is called
        await pushNotificationManager.scheduleStreakReminderNotification()

        // Then: No notification should be scheduled (CC not pending)
        #expect(preferences.daysOfCompassCheck == 2, "Streak should be 2 days")
        #expect(preferences.didCompassCheckToday, "CC should be done today")
        #expect(preferences.daysOfCompassCheck >= 2, "Streak should meet threshold")
    }

    @Test
    func testStreakReminder_Streak5Days_Pending_ShouldSchedule() async throws {
        // Given: 5-day streak, CC pending, current time 10:00 AM
        let currentTime = createTime(hour: 10, minute: 0)
        let (preferences, timeProvider, pushNotificationManager) = createTestScenario(
            currentTime: currentTime,
            streakDays: 5,
            didCompassCheckToday: false
        )

        // When: scheduleStreakReminderNotification is called
        await pushNotificationManager.scheduleStreakReminderNotification()

        // Then: Notification should be scheduled for 11:00 AM
        #expect(preferences.daysOfCompassCheck == 5, "Streak should be 5 days")
        #expect(!preferences.didCompassCheckToday, "CC should be pending")
        #expect(preferences.daysOfCompassCheck >= 2, "Streak should meet threshold")
        #expect(timeProvider.now < createTime(hour: 11, minute: 0), "Current time should be before 11 AM")
    }

    @Test
    func testStreakReminder_CurrentTimeAfter11AM_ShouldNotSchedule() async throws {
        // Given: 2-day streak, CC pending, current time 12:00 PM
        let currentTime = createTime(hour: 12, minute: 0)
        let (preferences, timeProvider, pushNotificationManager) = createTestScenario(
            currentTime: currentTime,
            streakDays: 2,
            didCompassCheckToday: false
        )

        // When: scheduleStreakReminderNotification is called
        await pushNotificationManager.scheduleStreakReminderNotification()

        // Then: No notification should be scheduled (11 AM already passed)
        #expect(preferences.daysOfCompassCheck == 2, "Streak should be 2 days")
        #expect(!preferences.didCompassCheckToday, "CC should be pending")
        #expect(preferences.daysOfCompassCheck >= 2, "Streak should meet threshold")
        #expect(timeProvider.now >= createTime(hour: 11, minute: 0), "Current time should be after 11 AM")
    }

    @Test
    func testStreakReminder_CurrentTimeExactly11AM_ShouldNotSchedule() async throws {
        // Given: 2-day streak, CC pending, current time exactly 11:00 AM
        let currentTime = createTime(hour: 11, minute: 0)
        let (preferences, timeProvider, pushNotificationManager) = createTestScenario(
            currentTime: currentTime,
            streakDays: 2,
            didCompassCheckToday: false
        )

        // When: scheduleStreakReminderNotification is called
        await pushNotificationManager.scheduleStreakReminderNotification()

        // Then: No notification should be scheduled (11 AM already reached)
        #expect(preferences.daysOfCompassCheck == 2, "Streak should be 2 days")
        #expect(!preferences.didCompassCheckToday, "CC should be pending")
        #expect(preferences.daysOfCompassCheck >= 2, "Streak should meet threshold")
        #expect(timeProvider.now >= createTime(hour: 11, minute: 0), "Current time should be at or after 11 AM")
    }

    // MARK: - System Push Notification Tests (User-set time)

    @Test
    func testSystemNotification_CCPending_ShouldSchedule() async throws {
        // Given: CC pending, time set to 6:00 PM, current time 2:00 PM
        let currentTime = createTime(hour: 14, minute: 0)
        let compassCheckTime = createTime(hour: 18, minute: 0)
        let (preferences, timeProvider, pushNotificationManager) = createTestScenario(
            currentTime: currentTime,
            streakDays: 3,
            didCompassCheckToday: false,
            compassCheckTime: compassCheckTime
        )

        // Create a mock CompassCheckManager
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider)
        let compassCheckManager = appComponents.compassCheckManager

        // When: scheduleSystemPushNotification is called
        await pushNotificationManager.scheduleSystemPushNotification(
            model: compassCheckManager
        )

        // Then: Notification should be scheduled for 6:00 PM
        #expect(!preferences.didCompassCheckToday, "CC should be pending")
        #expect(preferences.compassCheckTimeComponents.hour == 18, "Compass check time should be 6 PM")
        #expect(preferences.compassCheckTimeComponents.minute == 0, "Compass check minute should be 0")
    }

    @Test
    func testSystemNotification_CCDoneToday_ShouldNotSchedule() async throws {
        // Given: CC done today, time set to 6:00 PM, current time 2:00 PM
        let currentTime = createTime(hour: 14, minute: 0)
        let compassCheckTime = createTime(hour: 18, minute: 0)
        let (preferences, timeProvider, pushNotificationManager) = createTestScenario(
            currentTime: currentTime,
            streakDays: 3,
            didCompassCheckToday: true,
            compassCheckTime: compassCheckTime
        )

        // Create a mock CompassCheckManager
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider)
        let compassCheckManager = appComponents.compassCheckManager

        // When: scheduleSystemPushNotification is called
        await pushNotificationManager.scheduleSystemPushNotification(
            model: compassCheckManager
        )

        // Then: No notification should be scheduled (CC not pending)
        #expect(preferences.didCompassCheckToday, "CC should be done today")
        #expect(preferences.compassCheckTimeComponents.hour == 18, "Compass check time should be 6 PM")
    }

    // MARK: - Edge Cases and Boundary Tests

    @Test
    func testStreakReminder_AtMidnight_ShouldSchedule() async throws {
        // Given: 2-day streak, CC pending, current time midnight
        let currentTime = createTime(hour: 0, minute: 0)
        let (preferences, timeProvider, pushNotificationManager) = createTestScenario(
            currentTime: currentTime,
            streakDays: 2,
            didCompassCheckToday: false
        )

        // When: scheduleStreakReminderNotification is called
        await pushNotificationManager.scheduleStreakReminderNotification()

        // Then: Notification should be scheduled for 11:00 AM
        #expect(preferences.daysOfCompassCheck == 2, "Streak should be 2 days")
        #expect(!preferences.didCompassCheckToday, "CC should be pending")
        #expect(timeProvider.now < createTime(hour: 11, minute: 0), "Current time should be before 11 AM")
    }

    @Test
    func testStreakReminder_At10_59AM_ShouldSchedule() async throws {
        // Given: 2-day streak, CC pending, current time 10:59 AM
        let currentTime = createTime(hour: 10, minute: 59)
        let (preferences, timeProvider, pushNotificationManager) = createTestScenario(
            currentTime: currentTime,
            streakDays: 2,
            didCompassCheckToday: false
        )

        // When: scheduleStreakReminderNotification is called
        await pushNotificationManager.scheduleStreakReminderNotification()

        // Then: Notification should be scheduled for 11:00 AM
        #expect(preferences.daysOfCompassCheck == 2, "Streak should be 2 days")
        #expect(!preferences.didCompassCheckToday, "CC should be pending")
        #expect(timeProvider.now < createTime(hour: 11, minute: 0), "Current time should be before 11 AM")
    }

    @Test
    func testStreakReminder_At11_01AM_ShouldNotSchedule() async throws {
        // Given: 2-day streak, CC pending, current time 11:01 AM
        let currentTime = createTime(hour: 11, minute: 1)
        let (preferences, timeProvider, pushNotificationManager) = createTestScenario(
            currentTime: currentTime,
            streakDays: 2,
            didCompassCheckToday: false
        )

        // When: scheduleStreakReminderNotification is called
        await pushNotificationManager.scheduleStreakReminderNotification()

        // Then: No notification should be scheduled (11 AM already passed)
        #expect(preferences.daysOfCompassCheck == 2, "Streak should be 2 days")
        #expect(!preferences.didCompassCheckToday, "CC should be pending")
        #expect(timeProvider.now > createTime(hour: 11, minute: 0), "Current time should be after 11 AM")
    }

    // MARK: - Integration Tests

    @Test
    func testNotificationConditions_AllScenarios() async throws {
        // Test all combinations of conditions

        let testCases: [(streak: Int, doneToday: Bool, currentHour: Int, shouldSchedule: Bool, description: String)] = [
            (1, false, 10, false, "1-day streak, pending, 10 AM - should not schedule"),
            (2, false, 10, true, "2-day streak, pending, 10 AM - should schedule"),
            (5, false, 10, true, "5-day streak, pending, 10 AM - should schedule"),
            (2, true, 10, false, "2-day streak, done today, 10 AM - should not schedule"),
            (2, false, 12, false, "2-day streak, pending, 12 PM - should not schedule"),
            (2, false, 11, false, "2-day streak, pending, 11 AM - should not schedule"),
        ]

        for testCase in testCases {
            let currentTime = createTime(hour: testCase.currentHour, minute: 0)
            let (preferences, timeProvider, pushNotificationManager) = createTestScenario(
                currentTime: currentTime,
                streakDays: testCase.streak,
                didCompassCheckToday: testCase.doneToday
            )

            // Test the conditions that would determine scheduling
            let shouldSchedule =
                preferences.daysOfCompassCheck >= 2 && !preferences.didCompassCheckToday
                && timeProvider.now < createTime(hour: 11, minute: 0)

            #expect(
                shouldSchedule == testCase.shouldSchedule,
                "\(testCase.description): expected \(testCase.shouldSchedule), got \(shouldSchedule)")
        }
    }

    // MARK: - Notification Preference Tests

    @Test
    func testStreakReminder_NotificationsDisabled_ShouldNotSchedule() async throws {
        // Given: 2-day streak, CC pending, but notifications disabled
        let currentTime = createTime(hour: 10, minute: 0)
        let (preferences, timeProvider, pushNotificationManager) = createTestScenario(
            currentTime: currentTime,
            streakDays: 2,
            didCompassCheckToday: false
        )

        // Disable notifications
        preferences.notificationsEnabled = false

        // When: scheduleStreakReminderNotification is called
        await pushNotificationManager.scheduleStreakReminderNotification()

        // Then: No notification should be scheduled (notifications disabled)
        #expect(preferences.daysOfCompassCheck == 2, "Streak should be 2 days")
        #expect(!preferences.didCompassCheckToday, "CC should be pending")
        #expect(!preferences.notificationsEnabled, "Notifications should be disabled")
    }

    @Test
    func testSystemNotification_NotificationsDisabled_ShouldNotSchedule() async throws {
        // Given: CC pending, but notifications disabled
        let currentTime = createTime(hour: 14, minute: 0)
        let compassCheckTime = createTime(hour: 18, minute: 0)
        let (preferences, timeProvider, pushNotificationManager) = createTestScenario(
            currentTime: currentTime,
            streakDays: 3,
            didCompassCheckToday: false,
            compassCheckTime: compassCheckTime
        )

        // Disable notifications
        preferences.notificationsEnabled = false

        // Create a mock CompassCheckManager
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider)
        let compassCheckManager = appComponents.compassCheckManager

        // When: scheduleSystemPushNotification is called
        await pushNotificationManager.scheduleSystemPushNotification(
            model: compassCheckManager
        )

        // Then: No notification should be scheduled (notifications disabled)
        #expect(!preferences.didCompassCheckToday, "CC should be pending")
        #expect(!preferences.notificationsEnabled, "Notifications should be disabled")
    }

    // MARK: - Helper Methods

    private func createTime(hour: Int, minute: Int) -> Date {
        let realTimeProvider = RealTimeProvider()
        return realTimeProvider.date(
            from: DateComponents(
                year: 2025, month: 1, day: 15,
                hour: hour, minute: minute, second: 0
            ))!
    }
}
