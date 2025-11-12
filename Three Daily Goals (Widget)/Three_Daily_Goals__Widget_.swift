//
//  Three_Daily_Goals__Widget_.swift
//  Three Daily Goals (Widget)
//
//  Created by Klaus Kneupner on 21/12/2023.
//

import SwiftUI
import WidgetKit
import tdgCoreWidget

class Provider: AppIntentTimelineProvider {
    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        // Return a single recommendation for the default configuration
        let defaultConfig = ConfigurationAppIntent()
        let recommendation = AppIntentRecommendation(intent: defaultConfig, description: "Three Daily Goals")
        return [recommendation]
    }

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

        // Generate a timeline with more frequent updates to ensure data freshness
        let currentDate = timeProvider.now

        // Create entries for the next few hours with more frequent updates
        for hourOffset in 0..<3 {
            let entryDate = timeProvider.date(byAdding: .hour, value: hourOffset, to: currentDate) ?? currentDate
            let entry = PriorityEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        // Add a refresh entry in 15 minutes to ensure data stays fresh
        let refreshDate = timeProvider.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate
        let refreshEntry = PriorityEntry(date: refreshDate, configuration: configuration)
        entries.append(refreshEntry)

        return Timeline(entries: entries, policy: .atEnd)
    }

    // MARK: - AppIntentTimelineProvider Protocol Requirements

    func getSnapshot(
        for configuration: ConfigurationAppIntent, in context: Context, completion: @escaping (PriorityEntry) -> Void
    ) {
        let entry = PriorityEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(
        for configuration: ConfigurationAppIntent, in context: Context,
        completion: @escaping (Timeline<PriorityEntry>) -> Void
    ) {
        var entries: [PriorityEntry] = []
        let timeProvider = RealTimeProvider()

        // Generate a timeline with more frequent updates to ensure data freshness
        let currentDate = timeProvider.now

        // Create entries for the next few hours with more frequent updates
        for hourOffset in 0..<3 {
            let entryDate = timeProvider.date(byAdding: .hour, value: hourOffset, to: currentDate) ?? currentDate
            let entry = PriorityEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        // Add a refresh entry in 15 minutes to ensure data stays fresh
        let refreshDate = timeProvider.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate
        let refreshEntry = PriorityEntry(date: refreshDate, configuration: configuration)
        entries.append(refreshEntry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
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
            .containerBackground(Color.priority, for: .widget)
    }

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: Provider(),
            content: getView
        )
        .configurationDisplayName("Three Daily Goals")
        .description("Display your daily priorities and streak")
        .supportedFamilies(
            {
                #if os(watchOS)
                    [
                        .accessoryRectangular,
                        .accessoryCircular,
                        .accessoryInline,
                    ]
                #else
                    [
                        .systemSmall,
                        .systemMedium,
                        .systemLarge,
                        .systemExtraLarge,
                    ]
                #endif
            }())
    }
}

extension View {
    @ViewBuilder func widgetBackground<T: View>(@ViewBuilder content: () -> T) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget, content: content)
        } else {
            background(content())
        }
    }
}

#if os(watchOS)
    #Preview(as: .accessoryRectangular) {
        Three_Daily_Goals__Widget_()
    } timeline: {
        PriorityEntry(date: .now, configuration: ConfigurationAppIntent())
    }

    #Preview(as: .accessoryCircular) {
        Three_Daily_Goals__Widget_()
    } timeline: {
        PriorityEntry(date: .now, configuration: ConfigurationAppIntent())
    }

    #Preview(as: .accessoryInline) {
        Three_Daily_Goals__Widget_()
    } timeline: {
        PriorityEntry(date: .now, configuration: ConfigurationAppIntent())
    }
#else

    #Preview(as: .systemSmall) {
        Three_Daily_Goals__Widget_()
    } timeline: {
        PriorityEntry(date: .now, configuration: ConfigurationAppIntent())
        PriorityEntry(date: .now, configuration: ConfigurationAppIntent())
    }

    #Preview(as: .systemMedium) {
        Three_Daily_Goals__Widget_()
    } timeline: {
        PriorityEntry(date: .now, configuration: ConfigurationAppIntent())
    }

    #Preview(as: .systemLarge) {
        Three_Daily_Goals__Widget_()
    } timeline: {
        PriorityEntry(date: .now, configuration: ConfigurationAppIntent())
    }
#endif
