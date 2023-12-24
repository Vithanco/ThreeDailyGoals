//
//  Three_Daily_Goals__Widget_.swift
//  Three Daily Goals (Widget)
//
//  Created by Klaus Kneupner on 21/12/2023.
//

import WidgetKit
import SwiftUI
import SwiftData
import os

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
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Three_Daily_Goals__Widget_EntryView.self)
    )
    @Environment(\.modelContext) private var modelContext
    
    @State var today: DailyTasks? = nil
    
    func loadPriorities() -> DailyTasks {
        let fetchDescriptor = FetchDescriptor<DailyTasks>()
        
        do {
            let days = try modelContext.fetch(fetchDescriptor)
            if days.count > 1 {
                logger.error("days has \(days.count) entries! Why?")
                for d in days {
                    modelContext.delete(d)
                }
            }
            if let result = days.first {
                return result
            }
        }
        catch {
            logger.warning("no data available?")
        }
        let new = DailyTasks()
        modelContext.insert(new)
        return new
    }
    
    var entry: PriorityEntry
    
    var body: some View {
        if let today = today {
            WPriorities(priorities: today)
        } else {
            Text("Loading...").font(.title).foregroundStyle(mainColor).onAppear(perform: {today = loadPriorities()})

        }
            }
}

struct Three_Daily_Goals__Widget_: Widget {
    @Environment(\.modelContext) private var modelContext
    let kind: String = "Three_Daily_Goals__Widget_"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            Three_Daily_Goals__Widget_EntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .modelContainer(sharedModelContainer)
        }
    }
}

#Preview(as: .systemSmall) {
    Three_Daily_Goals__Widget_()
} timeline: {
    PriorityEntry(date: .now, configuration: ConfigurationAppIntent())
    PriorityEntry(date: .now, configuration: ConfigurationAppIntent())
}
