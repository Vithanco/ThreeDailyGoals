//
//  EventService.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 29/06/2024.
//

import EventKit
import SimpleCalendar
import os

/// Non-isolated service for handling EventKit operations
/// This class is not marked with @MainActor, so it can safely use EKEventStore
public final class EventService: @unchecked Sendable {
    private let eventStore = EKEventStore()
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "EventService"
    )
    
    /// Request calendar access and return the result
    func requestCalendarAccess() async throws -> Bool {
        return try await eventStore.requestFullAccessToEvents()
    }
    
    /// Fetch events for a given date range
    func fetchEvents(startDate: Date, endDate: Date) -> [TDGEvent] {
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        return eventStore.events(matching: predicate).map { TDGEvent(base: $0) }
    }
}
