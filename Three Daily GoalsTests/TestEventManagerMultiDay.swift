//
//  TestEventManagerMultiDay.swift
//  Three Daily GoalsTests
//
//  Test-driven development for multi-day task calendar event management
//  Tests should FAIL initially, then PASS after implementation
//

import Foundation
import EventKit
import Testing
@testable import Three_Daily_Goals
@testable import tdgCoreMain

// MARK: - Mock Event Service

/// Mock implementation of EventServiceProtocol for testing
final class MockEventService: EventServiceProtocol, @unchecked Sendable {
    // In-memory storage for mock events
    private var events: [String: MockEvent] = [:]
    private var nextEventId = 1

    // Mock calendar
    let mockCalendarId = "test-calendar-123"
    var shouldFailOperations = false

    struct MockEvent {
        let id: String
        var title: String
        var startDate: Date
        var endDate: Date
        var notes: String?
        var url: URL?
    }

    func requestCalendarAccess() async throws -> Bool {
        return !shouldFailOperations
    }

    func fetchEvents(startDate: Date, endDate: Date) -> [TDGEvent] {
        return [] // Not needed for these tests
    }

    func getAvailableCalendars() -> [EKCalendar] {
        // Return a mock calendar (note: can't create EKCalendar directly, so return empty)
        // EventManager will check availableCalendars.first, which will be nil
        // Instead, we'll need to handle this differently
        return []
    }

    func createEvent(
        title: String,
        startDate: Date,
        duration: TimeInterval,
        calendarId: String,
        notes: String? = nil,
        url: URL? = nil,
        alarmOffsetMinutes: Int = 0
    ) -> String? {
        guard !shouldFailOperations else { return nil }

        let eventId = "mock-event-\(nextEventId)"
        nextEventId += 1

        let mockEvent = MockEvent(
            id: eventId,
            title: title,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(duration),
            notes: notes,
            url: url
        )

        events[eventId] = mockEvent
        return eventId
    }

    func updateEvent(eventId: String, startDate: Date, duration: TimeInterval) -> Bool {
        guard !shouldFailOperations, var event = events[eventId] else { return false }

        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(duration)
        events[eventId] = event
        return true
    }

    func deleteEvent(eventId: String) -> Bool {
        guard !shouldFailOperations else { return false }
        events.removeValue(forKey: eventId)
        return true
    }

    func getEvent(byId eventId: String) -> EKEvent? {
        return nil // Not needed - we use getEventStartDate instead
    }

    func getEventStartDate(byId eventId: String) -> Date? {
        return events[eventId]?.startDate
    }

    func findEventByUrl(url: URL) -> EKEvent? {
        return nil // Not needed for these tests
    }

    // Custom method for tests to check mock event existence
    func getMockEvent(byId eventId: String) -> MockEvent? {
        return events[eventId]
    }

    // Helper to get event count for tests
    func getEventCount() -> Int {
        return events.count
    }
}

@Suite
@MainActor
struct TestEventManagerMultiDay {

    // Helper to create test calendar ID that mock service accepts
    let testCalendarId = "test-calendar-123"

    /// Test 1: Same Day Rescheduling Updates Event
    /// When rescheduling a task within the same day, it should UPDATE the existing event (not create new)
    @Test
    func sameDayReschedulingUpdatesExistingEvent() async throws {
        // Setup with mock service
        let mockService = MockEventService()
        let timeProvider = RealTimeProvider()
        let eventManager = EventManager(timeProvider: timeProvider, eventService: mockService)

        // Wait for async initialization to complete
        let granted = await eventManager.waitForInitialization()
        #expect(granted, "Calendar access should be granted with mock service")

        // Create a test task
        let task = TaskItem(title: "Test Task - Same Day", details: "Testing same-day rescheduling", state: .priority)

        // Given: Task scheduled for today at 2pm
        let today = Date()
        let twoPM = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: today)!

        let scheduleSuccess1 = await eventManager.scheduleTask(
            task,
            startDate: twoPM,
            duration: 3600,
            calendarId: mockService.mockCalendarId
        )
        #expect(scheduleSuccess1, "Initial scheduling should succeed")

        guard let originalEventId = task.eventId else {
            throw EventManagerTestError.noEventId
        }

        #expect(mockService.getEventCount() == 1, "Should have created 1 event")

        // When: Reschedule same task to 4pm today
        let fourPM = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: today)!

        let scheduleSuccess2 = await eventManager.scheduleTask(
            task,
            startDate: fourPM,
            duration: 3600,
            calendarId: mockService.mockCalendarId
        )
        #expect(scheduleSuccess2, "Rescheduling should succeed")

        // Then: Same event ID, event updated (not created new)
        #expect(task.eventId == originalEventId, "Event ID should remain the same for same-day rescheduling")
        #expect(mockService.getEventCount() == 1, "Should still have only 1 event (updated, not created new)")

        // Verify the event time was updated
        guard let updatedEvent = mockService.getMockEvent(byId: originalEventId) else {
            throw EventManagerTestError.eventNotFound
        }

        let updatedHour = Calendar.current.component(.hour, from: updatedEvent.startDate)
        #expect(updatedHour == 16, "Event should be updated to 4pm")

        // Cleanup
        _ = await eventManager.unscheduleTask(task)
    }

    /// Test 2: Different Day Creates New Event and Leaves Old One
    /// When rescheduling to a different day, it should CREATE a new event and LEAVE the old one
    @Test
    func differentDayCreatesNewEventLeavesOldOne() async throws {
        // Setup with mock service
        let mockService = MockEventService()
        let timeProvider = RealTimeProvider()
        let eventManager = EventManager(timeProvider: timeProvider, eventService: mockService)

        // Wait for async initialization to complete
        let granted = await eventManager.waitForInitialization()
        #expect(granted, "Calendar access should be granted with mock service")

        // Create a test task
        let task = TaskItem(title: "Test Task - Multi Day", details: "Testing different-day rescheduling", state: .priority)

        // Given: Task scheduled for Monday
        let calendar = Calendar.current
        let today = Date()
        let monday = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today)!

        let scheduleSuccess1 = await eventManager.scheduleTask(
            task,
            startDate: monday,
            duration: 3600,
            calendarId: mockService.mockCalendarId
        )
        #expect(scheduleSuccess1, "Monday scheduling should succeed")

        guard let mondayEventId = task.eventId else {
            throw EventManagerTestError.noEventId
        }

        #expect(mockService.getEventCount() == 1, "Should have 1 event after Monday scheduling")

        // When: Reschedule to Tuesday
        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!

        let scheduleSuccess2 = await eventManager.scheduleTask(
            task,
            startDate: tuesday,
            duration: 3600,
            calendarId: mockService.mockCalendarId
        )
        #expect(scheduleSuccess2, "Tuesday scheduling should succeed")

        guard let tuesdayEventId = task.eventId else {
            throw EventManagerTestError.noEventId
        }

        // Then: New event ID created, Monday event still exists
        #expect(tuesdayEventId != mondayEventId, "Should create new event ID for different day")
        #expect(mockService.getEventCount() == 2, "Should have 2 events (Monday + Tuesday)")

        // Verify Monday event still exists (historical record)
        let mondayEvent = mockService.getMockEvent(byId: mondayEventId)
        #expect(mondayEvent != nil, "Monday event should still exist in calendar (historical record)")

        // Verify Tuesday event exists
        let tuesdayEvent = mockService.getMockEvent(byId: tuesdayEventId)
        #expect(tuesdayEvent != nil, "Tuesday event should exist in calendar")

        // Cleanup both events
        _ = eventManager.eventService.deleteEvent(eventId: mondayEventId)
        _ = await eventManager.unscheduleTask(task)
    }

    /// Test 3: Historical Trail of Events
    /// When rescheduling across multiple days, all events should remain as historical trail
    @Test
    func multipleReschedulesCreateHistoricalTrail() async throws {
        // Setup with mock service
        let mockService = MockEventService()
        let timeProvider = RealTimeProvider()
        let eventManager = EventManager(timeProvider: timeProvider, eventService: mockService)

        // Wait for async initialization to complete
        let granted = await eventManager.waitForInitialization()
        #expect(granted, "Calendar access should be granted with mock service")

        // Create a test task
        let task = TaskItem(title: "Test Task - Historical Trail", details: "Testing multi-day historical trail", state: .priority)

        let calendar = Calendar.current
        let baseDate = Date()

        // Given: Task scheduled for Monday, Tuesday, Wednesday
        let monday = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: baseDate)!
        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!
        let wednesday = calendar.date(byAdding: .day, value: 2, to: monday)!

        // Schedule Monday
        _ = await eventManager.scheduleTask(task, startDate: monday, duration: 3600, calendarId: mockService.mockCalendarId)
        guard let mondayId = task.eventId else {
            throw EventManagerTestError.noEventId
        }

        // Schedule Tuesday
        _ = await eventManager.scheduleTask(task, startDate: tuesday, duration: 3600, calendarId: mockService.mockCalendarId)
        guard let tuesdayId = task.eventId else {
            throw EventManagerTestError.noEventId
        }

        // Schedule Wednesday
        _ = await eventManager.scheduleTask(task, startDate: wednesday, duration: 3600, calendarId: mockService.mockCalendarId)
        guard let wednesdayId = task.eventId else {
            throw EventManagerTestError.noEventId
        }

        // Then: All three events exist in calendar, task points to most recent
        #expect(mockService.getEventCount() == 3, "Should have 3 events (Mon/Tue/Wed trail)")

        let mondayEvent = mockService.getMockEvent(byId: mondayId)
        #expect(mondayEvent != nil, "Monday event should exist (historical record)")

        let tuesdayEvent = mockService.getMockEvent(byId: tuesdayId)
        #expect(tuesdayEvent != nil, "Tuesday event should exist (historical record)")

        let wednesdayEvent = mockService.getMockEvent(byId: wednesdayId)
        #expect(wednesdayEvent != nil, "Wednesday event should exist (current)")

        #expect(task.eventId == wednesdayId, "Task should point to most recent event (Wednesday)")

        // Cleanup all three events
        _ = eventManager.eventService.deleteEvent(eventId: mondayId)
        _ = eventManager.eventService.deleteEvent(eventId: tuesdayId)
        _ = await eventManager.unscheduleTask(task)
    }

    /// Test 4: Deleted Event Handled Gracefully
    /// When an event is deleted externally, rescheduling should create a new event
    @Test
    func deletedEventCreatesNewOne() async throws {
        // Setup with mock service
        let mockService = MockEventService()
        let timeProvider = RealTimeProvider()
        let eventManager = EventManager(timeProvider: timeProvider, eventService: mockService)

        // Wait for async initialization to complete
        let granted = await eventManager.waitForInitialization()
        #expect(granted, "Calendar access should be granted with mock service")

        // Create a test task
        let task = TaskItem(title: "Test Task - Deleted Event", details: "Testing graceful handling of deleted events", state: .priority)

        // Given: Task with scheduled event
        let today = Date()
        let startTime = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: today)!

        let scheduleSuccess = await eventManager.scheduleTask(
            task,
            startDate: startTime,
            duration: 3600,
            calendarId: mockService.mockCalendarId
        )
        #expect(scheduleSuccess, "Initial scheduling should succeed")

        guard let originalEventId = task.eventId else {
            throw EventManagerTestError.noEventId
        }

        #expect(mockService.getEventCount() == 1, "Should have 1 event initially")

        // When: Event deleted externally (simulating user deleting in Calendar app)
        let deleteSuccess = eventManager.eventService.deleteEvent(eventId: originalEventId)
        #expect(deleteSuccess, "External deletion should succeed")
        #expect(mockService.getEventCount() == 0, "Event should be deleted from mock store")

        // Then: Rescheduling should create new event
        let rescheduleSuccess = await eventManager.scheduleTask(
            task,
            startDate: startTime,
            duration: 3600,
            calendarId: mockService.mockCalendarId
        )
        #expect(rescheduleSuccess, "Rescheduling after deletion should succeed")

        // Verify new event created with different ID
        #expect(task.eventId != nil, "Task should have a new event ID")
        #expect(task.eventId != originalEventId, "New event ID should be different from deleted one")
        #expect(mockService.getEventCount() == 1, "Should have 1 new event")

        // Cleanup
        _ = await eventManager.unscheduleTask(task)
    }
}

// MARK: - Test Errors

enum EventManagerTestError: Error {
    case noCalendarAvailable
    case noEventId
    case eventNotFound
}
