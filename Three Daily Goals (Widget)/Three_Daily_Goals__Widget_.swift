//
//  Three_Daily_Goals__Widget_.swift
//  Three Daily Goals (Widget)
//
//  Created by Klaus Kneupner on 21/12/2023.
//

import SwiftData
import SwiftUI
import WidgetKit
import tdgCoreWidget

struct Provider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> PriorityEntry {
        return PriorityEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async
        -> PriorityEntry
    {
        return PriorityEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<
        PriorityEntry
    > {
        var entries: [PriorityEntry] = []
        let timeProvider = RealTimeProvider()

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = timeProvider.now
        for hourOffset in 0..<5 {
            let entryDate = timeProvider.date(byAdding: .hour, value: hourOffset, to: currentDate) ?? currentDate
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

struct Three_Daily_Goals__Widget_EntryView: View {
    var entry: PriorityEntry

    var body: some View {
        WPriorities(preferences: CloudPreferences(testData: false, timeProvider: RealTimeProvider()))
    }
}

struct Three_Daily_Goals__Widget_: Widget {

    let kind: String = "Three_Daily_Goals__Widget_"

    func getView(entry: PriorityEntry) -> some View {
        return Three_Daily_Goals__Widget_EntryView(entry: entry)
            .containerBackground(.fill.tertiary, for: .widget)
    }

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind, intent: ConfigurationAppIntent.self, provider: Provider(), content: getView)
    }
}

#Preview(as: .systemSmall) {
    Three_Daily_Goals__Widget_()
} timeline: {
    PriorityEntry(date: .now, configuration: ConfigurationAppIntent())
    PriorityEntry(date: .now, configuration: ConfigurationAppIntent())
}
