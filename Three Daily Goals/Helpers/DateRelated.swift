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


public func getReviewInterval (forDate: Date = Date.now) -> DateInterval {
    let calendar = Calendar.current
    
    let hour = calendar.component(.hour, from: forDate)
    
    var startDateComponents = calendar.dateComponents([.year, .month, .day], from: forDate)
    var endDateComponents = calendar.dateComponents([.year, .month, .day], from: forDate)
    
    startDateComponents.hour = 12
    endDateComponents.hour = 12
    if hour < 12 {
        // if AM
        startDateComponents.day! -= 1 // Yesterday
    } else {
        // if PM
        endDateComponents.day! += 1 // Tomorrow
    }
    
    guard let startDate = calendar.date(from: startDateComponents),
          let endDate = calendar.date(from: endDateComponents) else { return DateInterval(start: Date.now, duration: 0) }
    
    return DateInterval(start: startDate, end: endDate)
}


func getDate (daysPrior: Int) -> Date {
    guard let exact = Calendar.current.date(byAdding: .day, value: -1 * daysPrior, to: Date.now) else {
        assert(false, "Could not create date \(daysPrior)")
        return Date.now
    }
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
    static let thirtySeconds = 30.0
    static let fiveMin = 60.0 * 5.0
    static let oneHour = 60.0 * 60.0
    static let fullDay = oneHour * 24.0
    static let twoDays = fullDay * 2.0
    static let thirtySixHours = oneHour * 36.0
    static let fourHours = oneHour * 4.0
    static let twelveHours = oneHour * 12.0
    static let eightHours = oneHour * 8.0
}


extension Date {
    var isToday: Bool {
        return startOfDay == Date.today
    }
    
    var beginOfReviewWindow: Date {
        let inter = getReviewInterval(forDate: self)
        return inter.start
    }
    
    static var today: Date {
        return Calendar.current.startOfDay(for: now)
    }
    
    func timeAgoDisplay() -> String {
        return timeAgoFormatter.localizedString(for: self, relativeTo: Date())
    }
    
    var startOfDay: Date {
       return  Calendar.current.startOfDay(for:self)
    }
    
    var endOfDay: Date {
        return  Calendar.current.date(byAdding: DateComponents(hour: 23, minute: 59),to: startOfDay) ?? Date.now
    }
    
    var timeRemaining: String {
        return timeAgoFormatter.string(for: endOfDay) ?? ""
    }
}
