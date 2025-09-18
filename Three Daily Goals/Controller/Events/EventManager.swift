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

public enum CalendarAccess {
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

    private let eventService = EventService()
    private let timeProvider: TimeProvider
    private var startDate: Date
    private var endDate: Date
    private var calendar: Calendar

    init(timeProvider: TimeProvider) {
        self.timeProvider = timeProvider
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
            }
        } catch {
            let msg = "Error requesting calendar access: \(error.localizedDescription)"
            logger.error("\(msg)")
            state = .error(msg)
        }
    }

    func refresh(for range: Range<Date>? = nil) {
        if let r = range {
            startDate = r.lowerBound
            endDate = r.upperBound
        }
        if case .granted = state { 
            events = eventService.fetchEvents(startDate: startDate, endDate: endDate)
        }
    }
}
