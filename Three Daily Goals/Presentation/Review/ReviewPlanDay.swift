//
//  ReviewPlanDay.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 26/06/2024.
//

import SwiftUI
import SimpleCalendar
import EventKit

struct ReviewPlanDay: View {
    @Bindable var model: TaskManagerViewModel
    let eventMgr = EventManager()
    @State var events : [any CalendarEventRepresentable]
    @State var date: Date
    
    init(model: TaskManagerViewModel, date: Date) {
        self.model = model
        self._events = State(initialValue: eventMgr.events)
        self._date = State(initialValue: date)
    }
    
    var body: some View {
        VStack{
            Text("Book the time for your daily goals via drag'n'drop \(Image(systemName: "arrowshape.left.arrowshape.right.fill"))").font(.title2).foregroundStyle(model.accentColor).multilineTextAlignment(.center)
            HStack {
                SimpleCalendarView(events: $events, selectedDate: $date, selectionAction: .inform(self.onSelection) ,dateSelectionStyle: .selectedDates([Date.today]))
                ListView(whichList: .priority, model: model).frame(minHeight: 300)
            }
        }
    }
    
    func onSelection(event: any CalendarEventRepresentable) {
        
    }
}



#Preview {

   // return Text ("in total: \(events.count)")
    let  date = Date.today
    return  ReviewPlanDay(model: dummyViewModel(), date: date)
    
    
    
}
