//
//  DateRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 18/12/2023.
//

import Foundation



let stdDateFormat = Date.FormatStyle(date: .numeric, time: .none)

func getDate (daysPrior: Int) -> Date {
    let exact = Calendar.current.date(byAdding: .day, value: -1 * daysPrior, to: Date.now) ?? Date.now
    return Calendar.current.startOfDay(for: exact)
}



extension Date {
    var isToday: Bool {
        return Calendar.current.startOfDay(for:self) == Date.today
    }
    
    static var today: Date {
        return Calendar.current.startOfDay(for: now)
    }
}
