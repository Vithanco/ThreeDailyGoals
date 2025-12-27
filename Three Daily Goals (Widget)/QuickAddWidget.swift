//
//  QuickAddWidget.swift
//  Three Daily Goals (Widget)
//
//  Quick Add widget for creating new tasks from the home screen
//

import SwiftUI
import WidgetKit
import tdgCoreWidget

// MARK: - Widget Entry

struct QuickAddEntry: TimelineEntry {
    let date: Date
}

// MARK: - Timeline Provider

struct QuickAddProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickAddEntry {
        QuickAddEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickAddEntry) -> Void) {
        let entry = QuickAddEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickAddEntry>) -> Void) {
        // Since this widget is static, we only need one entry
        // Update once a day just to refresh
        let currentDate = Date()
        let nextUpdate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate

        let entry = QuickAddEntry(date: currentDate)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View

struct QuickAddWidgetView: View {
    var entry: QuickAddEntry
    @Environment(\.widgetFamily) var widgetFamily

    private var config: WidgetSizeConfig {
        WidgetSizeConfig.forFamily(widgetFamily)
    }

    var body: some View {
        Link(destination: URL(string: "three-daily-goals://new-task")!) {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.priority.opacity(0.9),
                        Color.priority
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Content
                VStack(spacing: widgetFamily == .systemSmall ? 8 : config.verticalSpacing * 2) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: iconSize, height: iconSize)

                        Image(systemName: imgPlus)
                            .font(.system(size: iconSize * 0.6, weight: .semibold))
                            .foregroundStyle(Color.white)
                    }

                    // Text
                    if widgetFamily == .systemSmall {
                        Text("Add Task")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    } else {
                        VStack(spacing: config.verticalSpacing / 2) {
                            Text("Quick Add")
                                .font(.system(size: titleFontSize, weight: .bold))
                                .foregroundStyle(Color.white)

                            Text("New Task")
                                .font(.system(size: subtitleFontSize, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.9))
                        }
                    }
                }
                .padding(widgetFamily == .systemSmall ? 12 : 16)
            }
        }
    }

    // MARK: - Size Calculations

    private var iconSize: CGFloat {
        switch widgetFamily {
        case .systemSmall:
            return 50
        case .systemMedium:
            return 55
        case .accessoryCircular:
            return 24
        case .accessoryRectangular:
            return 20
        default:
            return 50
        }
    }

    private var titleFontSize: CGFloat {
        switch widgetFamily {
        case .systemSmall:
            return 20
        case .systemMedium:
            return 18
        case .accessoryCircular:
            return 12
        case .accessoryRectangular:
            return 14
        default:
            return 20
        }
    }

    private var subtitleFontSize: CGFloat {
        switch widgetFamily {
        case .systemSmall:
            return 14
        case .systemMedium:
            return 13
        case .accessoryCircular:
            return 9
        case .accessoryRectangular:
            return 11
        default:
            return 14
        }
    }
}

// MARK: - Widget Configuration

struct QuickAddWidget: Widget {
    let kind: String = "QuickAddWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: QuickAddProvider()
        ) { entry in
            QuickAddWidgetView(entry: entry)
                .containerBackground(Color.priority, for: .widget)
        }
        .configurationDisplayName("Quick Add Task")
        .description("Quickly create a new task with camera support")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
        ])
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    QuickAddWidget()
} timeline: {
    QuickAddEntry(date: .now)
}

#Preview("Medium", as: .systemMedium) {
    QuickAddWidget()
} timeline: {
    QuickAddEntry(date: .now)
}
