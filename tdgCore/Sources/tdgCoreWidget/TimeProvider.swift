//
//  TimeProvider.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 2025-01-07.
//

import Foundation

/// Protocol for time operations to allow mocking in tests
public protocol TimeProvider: Sendable {
    var now: Date { get }
    var calendar: Calendar { get }
}

// MARK: - Protocol Extensions for Common Functionality

extension TimeProvider {
    // Helper methods for common time operations
    public func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date? {
        return calendar.date(byAdding: component, value: value, to: date)
    }

    public func date(bySettingHour hour: Int, minute: Int, second: Int, of date: Date) -> Date? {
        return calendar.date(bySettingHour: hour, minute: minute, second: second, of: date)
    }

    public func startOfDay(for date: Date) -> Date {
        return calendar.startOfDay(for: date)
    }

    public func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        return calendar.isDate(date1, inSameDayAs: date2)
    }

    // Component extraction methods
    public func component(_ component: Calendar.Component, from date: Date) -> Int {
        return calendar.component(component, from: date)
    }

    public func date(from components: DateComponents) -> Date? {
        return calendar.date(from: components)
    }

    public func isDateInTomorrow(_ date: Date) -> Bool {
        return calendar.isDateInTomorrow(date)
    }

    // The 4 core functions that need to be moved from DateRelated.swift
    public func getDate(daysPrior: Int) -> Date {
        guard let exact = calendar.date(byAdding: .day, value: -1 * daysPrior, to: now) else {
            assert(false, "Could not create date \(daysPrior)")
            return now
        }
        return calendar.startOfDay(for: exact)
    }

    public func getDate(hoursPrior: Int) -> Date {
        guard let exact = calendar.date(byAdding: .hour, value: -1 * hoursPrior, to: now) else {
            assert(false, "Could not create date \(hoursPrior) hours prior")
            return now
        }
        return exact
    }

    public func getDate(inDays: Int) -> Date {
        let exact = calendar.date(byAdding: .day, value: inDays, to: now) ?? now
        return calendar.startOfDay(for: exact)
    }

    public func todayAt(hour: Int, min: Int) -> Date {
        var h = hour
        if hour < 0 {
            h = 0
        } else if hour > 23 {
            h = 23
        }
        var m = min
        if min < 0 {
            m = 0
        } else if min > 59 {
            m = 59
        }

        var components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: now)

        components.minute = m
        components.hour = h
        components.second = 0

        return calendar.date(from: components) ?? now
    }

    public func getCompassCheckInterval(forDate: Date) -> DateInterval {
        let hour = calendar.component(.hour, from: forDate)

        // Create noon time for the given date
        var noonComponents = calendar.dateComponents([.year, .month, .day], from: forDate)
        noonComponents.hour = 12
        noonComponents.minute = 0
        noonComponents.second = 0

        guard let noonTime = calendar.date(from: noonComponents) else {
            return DateInterval(start: now, duration: 0)
        }

        guard hour < 12 else {
            // if PM: interval is from today noon to tomorrow noon
            let endDate = calendar.date(byAdding: .day, value: 1, to: noonTime) ?? noonTime
            return DateInterval(start: noonTime, end: endDate)
        }
        // if AM: interval is from yesterday noon to today noon
        let startDate = calendar.date(byAdding: .day, value: -1, to: noonTime) ?? noonTime
        return DateInterval(start: startDate, end: noonTime)
    }

    // Convenience method for current interval
    public func getCompassCheckInterval() -> DateInterval {
        return getCompassCheckInterval(forDate: now)
    }

    // Helper function for adding a day to a date
    public func addADay(_ date: Date) -> Date {
        return calendar.date(byAdding: .day, value: 1, to: date) ?? date
    }

    // Date extension methods moved from DateRelated.swift
    public func isToday(_ date: Date) -> Bool {
        return startOfDay(for: date) == startOfDay(for: now)
    }

    public func beginOfReviewWindow(for date: Date) -> Date {
        let inter = getCompassCheckInterval(forDate: date)
        return inter.start
    }

    public var today: Date {
        return startOfDay(for: now)
    }

    public func endOfDay(for date: Date) -> Date {
        return startOfDay(for: date).addingTimeInterval(24 * 60 * 60)
    }

    public func hour(of date: Date) -> Int {
        return calendar.component(.hour, from: date)
    }

    public func minute(of date: Date) -> Int {
        return calendar.component(.minute, from: date)
    }

    public func timeRemaining(for date: Date) -> String {
        return timeAgoFormatter.localizedString(for: date, relativeTo: now)
    }
}

// MARK: - Production Implementation

/// Production implementation that uses real system time
public struct RealTimeProvider: TimeProvider {
    public var now: Date { Date.now }
    public var calendar: Calendar { Calendar.current }
    public init() {
    }
}

// MARK: - Test Implementation

/// Test implementation that uses a fixed time
public struct MockTimeProvider: TimeProvider {
    public let fixedNow: Date
    public let testCalendar: Calendar

    public init(fixedNow: Date, calendar: Calendar = Calendar.current) {
        self.fixedNow = fixedNow
        self.testCalendar = calendar
    }

    public var now: Date { fixedNow }
    public var calendar: Calendar { testCalendar }
}

// MARK: - TimeProviderWrapper for SwiftUI Environment
@MainActor
@Observable
public class TimeProviderWrapper {
    public let timeProvider: TimeProvider

    public init(_ timeProvider: TimeProvider) {
        self.timeProvider = timeProvider
    }
}
