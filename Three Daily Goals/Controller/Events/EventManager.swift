//
//  EventHelper.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 29/06/2024.
//


import SwiftUI
import EventKit
import SimpleCalendar
import os

enum CalendarAccess {
    case granted
    case denied
    case error (String)
}


private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: Three_Daily_GoalsApp.self)
)

@Observable
final class EventManager {
    
    public var events : [TDGEvent] = []
    private let eventStore = EKEventStore()
    public var state: CalendarAccess = .denied
    
    var calendar : Calendar
    var startDate : Date
    var endDate : Date

    init() {
        calendar = Calendar.current
        var today = Calendar.current.startOfDay(for: Date.today)
        startDate = today
        endDate = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        requestCalendarAccess()
        events = fetchEvents()
    }
    
    func fetchEvents() -> [TDGEvent]{
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        return eventStore.events(matching: predicate).map({e in TDGEvent(base:e)})
    }

    private func requestCalendarAccess() {
        Task.init{
            do {
                let granted = try await self.eventStore.requestFullAccessToEvents()
                if granted {
                    logger.info("Calendar access granted")
                    state = .granted
                } else {
                    logger.warning("Calendar access denied")
                    state = .denied
                }
            } catch {
                logger.error("Error requesting calendar access: \(error.localizedDescription)")
                self.state = .error("Error requesting calendar access: \(error.localizedDescription)")
            }
        }
    }
}
