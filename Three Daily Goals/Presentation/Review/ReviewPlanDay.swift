//
//  ReviewPlanDay.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 26/06/2024.
//

import EventKit
import SimpleCalendar
import SwiftUI

extension TaskItem {
//    var asEvent: TDGEvent {
//        var result = TDGEvent(title: self.title, startDate: startDate, endDate: endDate)
//    }
}

struct ReviewPlanDay: View {
    @Bindable var model: TaskManagerViewModel
    let eventMgr = EventManager()
    @State var events: [any CalendarEventRepresentable]
    @State var date: Date

    init(model: TaskManagerViewModel, date: Date) {
        self.model = model
        self._events = State(initialValue: eventMgr.events)
        self._date = State(initialValue: date)
    }

    var body: some View {
        VStack {
            Text("Book the time for your daily goals via drag'n'drop \(Image(systemName: "arrowshape.left.arrowshape.right.fill"))").font(.title2).foregroundStyle(model.accentColor).multilineTextAlignment(.center)
            HStack {
                SimpleCalendarView(events: $events, selectedDate: $date, selectionAction: .inform(self.onSelection), dateSelectionStyle: .selectedDates([Date.today]))
                SimpleListView(
                    itemList: model.priorityTasks,
                    headers: [ListHeader.all],
                    showHeaders: false,
                    section: secToday,
                    id: TaskItemState.priority.getListAccessibilityIdentifier,
                    model: model
                )
                .frame(minHeight: 300)
                .dropDestination(for: String.self) {
                    items, _ in
                    for item in items.compactMap({model.findTask(withUuidString: $0)}){
                        return true
                    }
                    return true 
                }
            }
        }
    }

    func onSelection(event: any CalendarEventRepresentable) {}
}

#Preview {
    // return Text ("in total: \(events.count)")
    let date = Date.today
    let model = dummyViewModel()
    model.priorityTasks.first?.state = .priority
    return ReviewPlanDay(model: model, date: date)
}
