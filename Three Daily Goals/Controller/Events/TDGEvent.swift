//
//  TDGEvent.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/07/2024.
//

import EventKit
import Foundation
import SimpleCalendar
import SwiftUI

public struct TDGEvent: CalendarEventRepresentable {

    public var id: String {
        return base.calendarItemIdentifier
    }

    public var startDate: Date {
        return base.startDate
    }

    public var calendarActivity: any SimpleCalendar.CalendarActivityRepresentable {
        let calendar = self.calendar
        return CalendarActivity(
            id: calendar.calendarIdentifier, title: base.title, description: base.description,
            mentors: [],
            type: ActivityType(name: calendar.title, color: Color(cgColor: calendar.cgColor)),
            duration: self.duration)
    }

    public var coordinates: CGRect? = nil

    public var column: Int = 0

    public var columnCount: Int = 0

    let base: EKEvent
    var calendar: EKCalendar {
        return base.calendar
    }
    var duration: Double {
        return base.endDate.timeIntervalSince(base.startDate)
    }

}
