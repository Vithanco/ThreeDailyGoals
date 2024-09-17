//
//  TDGEvent.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/07/2024.
//

import Foundation
import EventKit
import SimpleCalendar
import SwiftUI


struct TDGEvent : CalendarEventRepresentable {
    
    var id: String {
        return base.calendarItemIdentifier
    }
    
    var startDate: Date {
        return base.startDate
    }
    
    var calendarActivity: any SimpleCalendar.CalendarActivityRepresentable  {
        let calendar = self.calendar
        return CalendarActivity(id: calendar.calendarIdentifier, title: base.title, description: base.description, mentors: [], type: ActivityType(name: calendar.title, color: Color(cgColor: calendar.cgColor)), duration: self.duration)
    }
    
    var coordinates: CGRect? = nil
    
    var column: Int = 0
    
    var columnCount: Int = 0
    
    
    let base : EKEvent
    var calendar: EKCalendar {
        return base.calendar
    }
    var duration: Double {
        return base.endDate.timeIntervalSince(base.startDate)
    }
    
}
