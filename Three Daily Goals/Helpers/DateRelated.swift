//
//  DateRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 18/12/2023.
//

import Foundation

let stdOnlyDateFormat = Date.FormatStyle(date: .numeric, time: .none)
let stdOnlyTimeFormat = Date.FormatStyle(date: .none, time: .shortened)
let stdDateTimeFormat = Date.FormatStyle(date: .numeric, time: .shortened)

// getCal() function removed - use TimeProvider instead


nonisolated(unsafe) let timeAgoFormatter = {
    let result = RelativeDateTimeFormatter()
    result.unitsStyle = .full
    return result
}()

// All calendar functions have been moved to TimeProvider
// Use TimeProvider instead of these legacy functions

enum Seconds {
    static let thirtySeconds = 30.0
    static let oneMin = 60.0 * 1.0
    static let fiveMin = 60.0 * 5.0
    static let oneHour = 60.0 * 60.0
    static let twoHours = oneHour * 2.0
    static let fullDay = oneHour * 24.0
    static let twoDays = fullDay * 2.0
    static let thirtySixHours = oneHour * 36.0
    static let fourHours = oneHour * 4.0
    static let twelveHours = oneHour * 12.0
    static let eightHours = oneHour * 8.0
}

extension Date {
    // Only keep non-calendar related methods
    @MainActor func timeAgoDisplay() -> String {
        return timeAgoFormatter.localizedString(for: self, relativeTo: Date())
    }

}
