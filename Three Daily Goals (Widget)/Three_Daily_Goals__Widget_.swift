//
//  Three_Daily_Goals__Widget_.swift
//  Three Daily Goals (Widget)
//
//  Created by Klaus Kneupner on 21/12/2023.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: AppIntentTimelineProvider {
    
    func placeholder(in context: Context) -> PriorityEntry {
        PriorityEntry(date: Date(), configuration: ConfigurationAppIntent())
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> PriorityEntry {
        PriorityEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<PriorityEntry> {
        var entries: [PriorityEntry] = []
        
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = PriorityEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }
        
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct PriorityEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    
}

struct Three_Daily_Goals__Widget_EntryView : View {

    @Environment(\.modelContext) private var modelContext
//    @Query(filter: #Predicate<TaskItem> { item in
//        item._state == TaskItemState.priority
//    }, sort: \.changed, order: .forward)
    @Query
    var list : [TaskItem]
    
    var entry: PriorityEntry
    
    var body: some View {
        WPriorities(priorities: list.filter({$0.isPriority}))
    }
}

struct Three_Daily_Goals__Widget_: Widget {
    @Environment(\.modelContext) private var modelContext
    let kind: String = "Three_Daily_Goals__Widget_"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            Three_Daily_Goals__Widget_EntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .modelContainer(sharedModelContainer(inMemory: false))
        }
    }
}

#Preview(as: .systemSmall) {
    Three_Daily_Goals__Widget_()
} timeline: {
    PriorityEntry(date: .now, configuration: ConfigurationAppIntent())
    PriorityEntry(date: .now, configuration: ConfigurationAppIntent())
}
