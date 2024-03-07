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
let timeAgoFormatter = {
    let result = RelativeDateTimeFormatter()
    result.unitsStyle = .full
    return result
}()
let nextReviewFormatter = {
    let result = RelativeDateTimeFormatter()
    result.unitsStyle = .short
    return result
}()


func getDate (daysPrior: Int) -> Date {
    let exact = Calendar.current.date(byAdding: .day, value: -1 * daysPrior, to: Date.now) ?? Date.now
    return Calendar.current.startOfDay(for: exact)
}

func getDate (inDays: Int) -> Date {
    let exact = Calendar.current.date(byAdding: .day, value: inDays, to: Date.now) ?? Date.now
    return Calendar.current.startOfDay(for: exact)
}


func addADay(_ result: Date) -> Date {
    return Calendar.current.date(byAdding: .day, value: 1, to: result) ?? Date.now
}

func todayAt(hour: Int, min: Int) -> Date {
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
    let calendar = Calendar.current
    
    var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date.now)
    
    components.minute = m
    components.hour = h
    components.second = 0
    
    return calendar.date(from: components) ?? Date.now
}

let sevenDaysAgo = getDate(daysPrior: 7)
let thirtyDaysAgo = getDate(daysPrior: 30)

enum Seconds{
    static var thirtySeconds = 30.0
    static var fiveMin = 60.0 * 5.0
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
