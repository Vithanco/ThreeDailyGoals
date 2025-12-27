//
//  EventManager.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 29/06/2024.
//

import EventKit
import SimpleCalendar
import SwiftUI
import os
import tdgCoreMain

public enum CalendarAccess: Equatable {
    case granted
    case denied
    case error(String)
}

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: Three_Daily_GoalsApp.self)
)

@MainActor
@Observable
public final class EventManager {
    public private(set) var events: [TDGEvent] = []
    public private(set) var state: CalendarAccess = .denied
    public private(set) var availableCalendars: [EKCalendar] = []

    public let eventService: EventServiceProtocol
    private let timeProvider: TimeProvider
    private var startDate: Date
    private var endDate: Date
    private var calendar: Calendar

    // Continuation for waiting on initialization completion
    private var initializationContinuations: [CheckedContinuation<Bool, Never>] = []

    init(timeProvider: TimeProvider, eventService: EventServiceProtocol? = nil) {
        self.timeProvider = timeProvider
        self.eventService = eventService ?? EventService()
        self.calendar = timeProvider.calendar
        let today = timeProvider.startOfDay(for: timeProvider.now)
        self.startDate = today
        self.endDate = timeProvider.date(byAdding: .day, value: 1, to: today) ?? today

        // Fire-and-forget: Start the async operation without waiting
        Task {
            await startAsync()
        }
    }

    /// Fire-and-forget async initialization
    private func startAsync() async {
        do {
            let granted = try await eventService.requestCalendarAccess()
            state = granted ? .granted : .denied
            if granted {
                events = eventService.fetchEvents(startDate: startDate, endDate: endDate)
                availableCalendars = eventService.getAvailableCalendars()
            }
            // Resume all waiting continuations
            completeInitialization(granted: granted)
        } catch {
            let msg = "Error requesting calendar access: \(error.localizedDescription)"
            logger.error("\(msg)")
            state = .error(msg)
            // Resume all waiting continuations with false (not granted)
            completeInitialization(granted: false)
        }
    }

    /// Complete initialization and resume all waiting continuations
    private func completeInitialization(granted: Bool) {
        for continuation in initializationContinuations {
            continuation.resume(returning: granted)
        }
        initializationContinuations.removeAll()
    }

    /// Wait for calendar access initialization to complete (useful for testing)
    /// - Returns: True if access was granted, false otherwise
    public func waitForInitialization() async -> Bool {
        // If already initialized (not denied), return immediately
        if state != .denied {
            return state == .granted
        }

        // Otherwise, wait for initialization to complete
        return await withCheckedContinuation { continuation in
            initializationContinuations.append(continuation)
        }
    }

    func refresh(for range: Range<Date>? = nil) {
        if let r = range {
            startDate = r.lowerBound
            endDate = r.upperBound
        }
        if case .granted = state {
            events = eventService.fetchEvents(startDate: startDate, endDate: endDate)
            availableCalendars = eventService.getAvailableCalendars()
        }
    }

    /// Schedule a task to the calendar
    /// - Parameters:
    ///   - task: The task to schedule
    ///   - startDate: When the task should start
    ///   - duration: How long the task should take (in seconds)
    ///   - calendarId: Target calendar identifier
    /// - Returns: True if successful, false otherwise
    @MainActor
    func scheduleTask(
        _ task: tdgCoreMain.TaskItem,
        startDate: Date,
        duration: TimeInterval,
        calendarId: String
    ) async -> Bool {
        guard case .granted = state else {
            logger.error("Calendar access not granted")
            return false
        }

        // Build deep link URL
        let deepLinkURL = URL(string: "three-daily-goals://task/\(task.uuid.uuidString)")

        // Check if event already exists for this task (using stored eventId)
        if let storedEventId = task.eventId {
            // Try to retrieve existing event's start date
            if let existingEventStart = eventService.getEventStartDate(byId: storedEventId) {
                // Compare event date with new scheduling date
                let existingDay = timeProvider.startOfDay(for: existingEventStart)
                let newDay = timeProvider.startOfDay(for: startDate)

                if existingDay == newDay {
                    // SAME DAY: Update existing event (move within day)
                    logger.info("Updating existing event for task: \(task.title) - same day")
                    let success = eventService.updateEvent(
                        eventId: storedEventId,
                        startDate: startDate,
                        duration: duration
                    )

                    if success {
                        // Refresh events to show updated version
                        refresh()
                        return true
                    }
                } else {
                    // DIFFERENT DAY: Leave old event alone (historical record)
                    // Just clear the eventId so we create a new one below
                    logger.info("Scheduling task '\(task.title)' for different day - leaving old event, creating new")
                    task.setCalendarEventId(nil)
                }
            } else {
                // Event doesn't exist anymore (deleted externally), clear ID
                logger.warning("Stored event ID is invalid, creating new event")
                task.setCalendarEventId(nil)
            }
        }

        // Create new event (either no event existed, or we're scheduling a different day)
        logger.info("Creating new event for task: \(task.title)")
        if let newEventId = eventService.createEvent(
            title: task.title,
            startDate: startDate,
            duration: duration,
            calendarId: calendarId,
            notes: task.details.isEmpty ? nil : task.details,
            url: deepLinkURL,
            alarmOffsetMinutes: 0  // Reminder at event time
        ) {
            // Store the event ID in the task
            task.setCalendarEventId(newEventId)

            // Refresh events to show new event
            refresh()
            return true
        } else {
            return false
        }
    }

    /// Unschedule a task from the calendar
    /// - Parameter task: The task to unschedule
    /// - Returns: True if successful or event not found, false on error
    @MainActor
    func unscheduleTask(_ task: tdgCoreMain.TaskItem) async -> Bool {
        guard case .granted = state else {
            logger.error("Calendar access not granted")
            return false
        }

        guard let eventId = task.eventId else {
            // No event ID stored - nothing to delete
            return true
        }

        let success = eventService.deleteEvent(eventId: eventId)

        if success {
            // Clear the stored event ID
            task.setCalendarEventId(nil)
            refresh()
        }

        return success
    }

    /// Check if a task is already scheduled in the calendar
    /// - Parameter task: The task to check
    /// - Returns: True if the task has a calendar event, false otherwise
    func isTaskScheduled(_ task: tdgCoreMain.TaskItem) -> Bool {
        guard case .granted = state else {
            return false
        }

        // Simply check if task has an eventId stored
        return task.eventId != nil
    }

    /// Check if task's calendar event is outdated (different day than target date)
    /// - Parameters:
    ///   - task: The task to check
    ///   - targetDate: The date to compare against
    /// - Returns: True if event exists but is on a different day than target date
    func isEventOutdated(_ task: tdgCoreMain.TaskItem, targetDate: Date) -> Bool {
        guard let eventId = task.eventId,
              let eventStart = eventService.getEventStartDate(byId: eventId) else {
            return false
        }

        let eventDay = timeProvider.startOfDay(for: eventStart)
        let targetDay = timeProvider.startOfDay(for: targetDate)

        return eventDay != targetDay
    }
}
