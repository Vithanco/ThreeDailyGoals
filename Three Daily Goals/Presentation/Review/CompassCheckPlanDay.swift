//
//  ReviewPlanDay.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 26/06/2024.
//

import EventKit
import SimpleCalendar
import SwiftUI
import tdgCoreMain

extension TaskItem {
    //    var asEvent: TDGEvent {
    //        var result = TDGEvent(title: self.title, startDate: startDate, endDate: endDate)
    //    }
}

public struct CompassCheckPlanDay: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(CloudPreferences.self) private var preferences
    @Environment(CompassCheckManager.self) private var compassCheckManager
    @Environment(TimeProviderWrapper.self) private var timeProviderWrapper
    @State var eventMgr: EventManager?
    @State var events: [any CalendarEventRepresentable] = []
    @State var date: Date

    init(date: Date) {
        self._date = State(initialValue: date)
    }
    
    private func setupEventManager() {
        if eventMgr == nil {
            let newEventMgr = EventManager(timeProvider: timeProviderWrapper.timeProvider)
            eventMgr = newEventMgr
            events = newEventMgr.events
        }
    }

    public var body: some View {
        VStack {
            Text("This is under development and not yet working.").font(.title)
            Text(
                "Book the time for your daily goals via drag'n'drop \(Image(systemName: "arrowshape.left.arrowshape.right.fill"))"
            ).font(.title2).foregroundStyle(Color.priority).multilineTextAlignment(.center)
            HStack {
                SimpleCalendarView(
                    events: $events,
                    selectedDate: $date,
                    selectionAction: .inform(self.onSelection),
                    dateSelectionStyle: .selectedDates([date])
                )
                SimpleListView(
                    color: .priority,
                    itemList: compassCheckManager.priorityTasks,
                    headers: [ListHeader.all],
                    showHeaders: false,
                    section: secToday,
                    id: TaskItemState.priority.getListAccessibilityIdentifier
                )
                .frame(minHeight: 300)
                .dropDestination(for: String.self) {
                    items, _ in
                    for _ in items.compactMap({ dataManager.findTask(withUuidString: $0) }) {
                        return true
                    }
                    return true
                }
            }
        }
        .onAppear {
            setupEventManager()
        }
    }

    func onSelection(event: any CalendarEventRepresentable) {}
}

#Preview {

    // return Text ("in total: \(events.count)")
    let timeProvider = RealTimeProvider()
    let date = timeProvider.today
    CompassCheckPlanDay(date: date)
}
