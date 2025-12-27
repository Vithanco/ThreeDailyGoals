//
//  EventService.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 29/06/2024.
//

import EventKit
import SimpleCalendar
import os

/// Protocol for event service operations (enables testing with mocks)
public protocol EventServiceProtocol: Sendable {
    func requestCalendarAccess() async throws -> Bool
    func fetchEvents(startDate: Date, endDate: Date) -> [TDGEvent]
    func getAvailableCalendars() -> [EKCalendar]
    func createEvent(title: String, startDate: Date, duration: TimeInterval, calendarId: String, notes: String?, url: URL?, alarmOffsetMinutes: Int) -> String?
    func updateEvent(eventId: String, startDate: Date, duration: TimeInterval) -> Bool
    func deleteEvent(eventId: String) -> Bool
    func getEvent(byId eventId: String) -> EKEvent?
    func getEventStartDate(byId eventId: String) -> Date?
    func findEventByUrl(url: URL) -> EKEvent?
}

/// Non-isolated service for handling EventKit operations
/// This class is not marked with @MainActor, so it can safely use EKEventStore
public final class EventService: EventServiceProtocol, @unchecked Sendable {
    private let eventStore = EKEventStore()
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "EventService"
    )

    /// Request calendar access and return the result
    public func requestCalendarAccess() async throws -> Bool {
        return try await eventStore.requestFullAccessToEvents()
    }

    /// Fetch events for a given date range
    public func fetchEvents(startDate: Date, endDate: Date) -> [TDGEvent] {
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        return eventStore.events(matching: predicate).map { TDGEvent(base: $0) }
    }

    /// Get list of writable calendars
    public func getAvailableCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
    }

    /// Create a new calendar event
    /// - Parameters:
    ///   - title: Event title
    ///   - startDate: Event start date/time
    ///   - duration: Event duration in seconds
    ///   - calendarId: Calendar identifier where event should be created
    ///   - notes: Optional notes/details for the event
    ///   - url: Optional URL to attach to the event
    ///   - alarmOffsetMinutes: Alarm time in minutes before event (0 = at event time, negative = before)
    /// - Returns: Event identifier if successful, nil otherwise
    public func createEvent(
        title: String,
        startDate: Date,
        duration: TimeInterval,
        calendarId: String,
        notes: String? = nil,
        url: URL? = nil,
        alarmOffsetMinutes: Int = 0
    ) -> String? {
        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
            logger.error("Calendar with ID \(calendarId) not found")
            return nil
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = title
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(duration)
        event.notes = notes
        event.url = url

        // Add alarm
        let alarm = EKAlarm(relativeOffset: TimeInterval(alarmOffsetMinutes * 60))
        event.addAlarm(alarm)

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            logger.info("Created event: \(title) with ID: \(event.eventIdentifier ?? "unknown")")
            return event.eventIdentifier
        } catch {
            logger.error("Failed to create event: \(error.localizedDescription)")
            return nil
        }
    }

    /// Update an existing calendar event's time and duration
    /// - Parameters:
    ///   - eventId: Event identifier
    ///   - startDate: New start date/time
    ///   - duration: New duration in seconds
    /// - Returns: True if successful, false otherwise
    public func updateEvent(eventId: String, startDate: Date, duration: TimeInterval) -> Bool {
        guard let event = eventStore.event(withIdentifier: eventId) else {
            logger.error("Event with ID \(eventId) not found")
            return false
        }

        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(duration)

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            logger.info("Updated event: \(event.title ?? "untitled")")
            return true
        } catch {
            logger.error("Failed to update event: \(error.localizedDescription)")
            return false
        }
    }

    /// Find an event by its URL
    /// - Parameter url: The URL to search for
    /// - Returns: The event if found, nil otherwise
    public func findEventByUrl(url: URL) -> EKEvent? {
        // Search through all calendars for events with matching URL
        // Note: This is not very efficient for large date ranges
        // We search within a reasonable range (e.g., ±1 year)
        let now = Date()
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        let oneYearAhead = Calendar.current.date(byAdding: .year, value: 1, to: now) ?? now

        let predicate = eventStore.predicateForEvents(
            withStart: oneYearAgo,
            end: oneYearAhead,
            calendars: nil
        )
        let events = eventStore.events(matching: predicate)

        return events.first { $0.url == url }
    }

    /// Delete an event by its identifier
    /// - Parameter eventId: Event identifier
    /// - Returns: True if successful, false otherwise
    public func deleteEvent(eventId: String) -> Bool {
        guard let event = eventStore.event(withIdentifier: eventId) else {
            logger.error("Event with ID \(eventId) not found for deletion")
            return false
        }

        do {
            try eventStore.remove(event, span: .thisEvent, commit: true)
            logger.info("Deleted event: \(event.title ?? "untitled")")
            return true
        } catch {
            logger.error("Failed to delete event: \(error.localizedDescription)")
            return false
        }
    }

    /// Get event details by identifier
    /// - Parameter eventId: Event identifier
    /// - Returns: The event if found, nil otherwise
    public func getEvent(byId eventId: String) -> EKEvent? {
        return eventStore.event(withIdentifier: eventId)
    }

    /// Get event start date by identifier (helper for testing)
    /// - Parameter eventId: Event identifier
    /// - Returns: The event's start date if found, nil otherwise
    public func getEventStartDate(byId eventId: String) -> Date? {
        return eventStore.event(withIdentifier: eventId)?.startDate
    }
}
