//
//  DateRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 18/12/2023.
//

import Foundation



let stdDateFormat = Date.FormatStyle(date: .numeric, time: .none)
let stdTimeFormat = Date.FormatStyle(date: .none, time: .shortened)
let timeAgoFormatter = {
    let result = RelativeDateTimeFormatter()
    result.unitsStyle = .full
    return result
}()

func getDate (daysPrior: Int) -> Date {
    let exact = Calendar.current.date(byAdding: .day, value: -1 * daysPrior, to: Date.now) ?? Date.now
    return Calendar.current.startOfDay(for: exact)
}

let sevenDaysAgo = getDate(daysPrior: 7)
let thirtyDaysAgo = getDate(daysPrior: 30)

enum Seconds{
    static var oneHour = 60.0 * 60.0
    static var fullDay = oneHour * 24.0
    static var twoDays = fullDay * 2.0
    static var thirtySixHours = oneHour * 36.0
    static var fourHours = oneHour * 4.0
    static var twelveHours = oneHour * 12.0
    static var eightHours = oneHour * 8.0
}


extension Date {
    var isToday: Bool {
        return Calendar.current.startOfDay(for:self) == Date.today
    }
    
    static var today: Date {
        return Calendar.current.startOfDay(for: now)
    }
    
    func timeAgoDisplay() -> String {
        return timeAgoFormatter.localizedString(for: self, relativeTo: Date())
    }
}
