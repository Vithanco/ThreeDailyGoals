//
//  ReviewPlanDay.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 26/06/2024.
//

import SwiftUI
import SimpleCalendar

struct ReviewPlanDay: View {
    @Bindable var model: TaskManagerViewModel
    @State var events: [any CalendarEventRepresentable]
    @State var date: Date
    
    init(model: TaskManagerViewModel, events: [any CalendarEventRepresentable], date: Date) {
        self.model = model
        self._events = State(initialValue: events)
        self._date = State(initialValue: date)
    }
    
    var body: some View {
        SimpleCalendarView(events: $events, selectedDate: $date)
    }
}

#Preview {
    let events = [CalendarEvent(id: "ok", startDate: .today, activity: CalendarActivity(id: "ok", title: "hey", description: "some more data", mentors: ["klaus"], type: ActivityType(name: "my calendar", color: .blue), duration: Seconds.oneHour))]
    let  date = Date.today
    return  ReviewPlanDay(model: dummyViewModel(),events: events , date: date)
}
