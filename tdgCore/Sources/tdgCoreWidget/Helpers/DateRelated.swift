//
//  DateRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 18/12/2023.
//

import Foundation

public let stdOnlyDateFormat = Date.FormatStyle(date: .numeric, time: .none)
public let stdOnlyTimeFormat = Date.FormatStyle(date: .none, time: .shortened)
public let stdDateTimeFormat = Date.FormatStyle(date: .numeric, time: .shortened)

// getCal() function removed - use TimeProvider instead

nonisolated(unsafe) public let timeAgoFormatter = {
    let result = RelativeDateTimeFormatter()
    result.unitsStyle = .full
    return result
}()

// All calendar functions have been moved to TimeProvider
// Use TimeProvider instead of these legacy functions

public enum Seconds {
    public static let thirtySeconds = 30.0
    public static let oneMin = 60.0 * 1.0
    public static let fiveMin = 60.0 * 5.0
    public static let oneHour = 60.0 * 60.0
    public static let twoHours = oneHour * 2.0
    public static let fullDay = oneHour * 24.0
    public static let twoDays = fullDay * 2.0
    public static let thirtySixHours = oneHour * 36.0
    public static let fourHours = oneHour * 4.0
    public static let twelveHours = oneHour * 12.0
    public static let eightHours = oneHour * 8.0
}

/// Hours before a task is ready for Energy-Effort Matrix classification
/// Tasks must be at least this old before they appear in the categorization step
public let hoursBeforeReadyForClassification: Int = 55

extension Date {
    // Only keep non-calendar related methods
    @MainActor public func timeAgoDisplay() -> String {
        return timeAgoFormatter.localizedString(for: self, relativeTo: Date())
    }

}
