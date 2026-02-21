//
//  GetMeATaskWidget.swift
//  Three Daily Goals (Widget)
//
//  Created by Claude Code on 30/12/2024.
//

import Foundation
import SwiftUI
import WidgetKit
import SwiftData
import tdgCoreWidget
import tdgCoreMain
import AppIntents

// MARK: - Timeline Entry

struct GetMeATaskEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let quadrantAvailability: [EnergyEffortQuadrant: Bool]
    let selectedQuadrant: EnergyEffortQuadrant?
    let selectedTask: TaskInfo?
}

struct TaskInfo: Sendable {
    let title: String
    let uuid: String
    let state: TaskItemState
}

// MARK: - Provider

struct GetMeATaskProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> GetMeATaskEntry {
        GetMeATaskEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            quadrantAvailability: [:],
            selectedQuadrant: nil,
            selectedTask: nil
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> GetMeATaskEntry {
        let (availability, selectedQuadrant, selectedTask) = await MainActor.run {
            let preferences = CloudPreferences(testData: false, timeProvider: RealTimeProvider())
            return loadTaskData(preferences: preferences)
        }

        return GetMeATaskEntry(
            date: Date(),
            configuration: configuration,
            quadrantAvailability: availability,
            selectedQuadrant: selectedQuadrant,
            selectedTask: selectedTask
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<GetMeATaskEntry> {
        let (availability, selectedQuadrant, selectedTask) = await MainActor.run {
            let preferences = CloudPreferences(testData: false, timeProvider: RealTimeProvider())
            return loadTaskData(preferences: preferences)
        }

        let entry = GetMeATaskEntry(
            date: Date(),
            configuration: configuration,
            quadrantAvailability: availability,
            selectedQuadrant: selectedQuadrant,
            selectedTask: selectedTask
        )

        // Only refresh on explicit reload - app calls WidgetCenter.reloadAllTimelines() when tasks change
        return Timeline(entries: [entry], policy: .never)
    }

    @MainActor
    private func loadTaskData(preferences: CloudPreferences) -> ([EnergyEffortQuadrant: Bool], EnergyEffortQuadrant?, TaskInfo?) {
        // Access the shared model container directly
        guard case .success(let container) = sharedModelContainer(inMemory: false, withCloud: true) else {
            return ([:], nil, nil)
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<TaskItem>()

        guard let allTasks = try? context.fetch(descriptor) else {
            return ([:], nil, nil)
        }

        // Get tasks that are either priority or open
        let activeTasks = allTasks.filter { $0.isOpenOrPriority }

        // Group tasks by quadrant
        var quadrantTasks: [EnergyEffortQuadrant: [TaskItem]] = [:]
        for quadrant in EnergyEffortQuadrant.allCases {
            quadrantTasks[quadrant] = []
        }

        // Categorize tasks by their quadrant
        for task in activeTasks {
            if let quadrant = EnergyEffortQuadrant.from(task: task) {
                quadrantTasks[quadrant]?.append(task)
            }
        }

        // Build availability map
        var availability: [EnergyEffortQuadrant: Bool] = [:]
        for quadrant in EnergyEffortQuadrant.allCases {
            availability[quadrant] = !(quadrantTasks[quadrant]?.isEmpty ?? true)
        }

        // Get selected quadrant if any
        var selectedQuadrant: EnergyEffortQuadrant?
        var selectedTask: TaskInfo?

        if let selectedQuadrantString = preferences.getSelectedQuadrant(),
           let quadrant = EnergyEffortQuadrant.fromStoredValue(selectedQuadrantString),
           let tasks = quadrantTasks[quadrant], !tasks.isEmpty {

            selectedQuadrant = quadrant

            // Sort tasks: priority tasks first (by oldest changed), then open tasks (by oldest changed)
            let sortedTasks = tasks.sorted { task1, task2 in
                // If one is priority and the other isn't, priority comes first
                if task1.isPriority && !task2.isPriority {
                    return true
                }
                if !task1.isPriority && task2.isPriority {
                    return false
                }
                // Both are the same state, sort by oldest changed date
                return task1.changed < task2.changed
            }

            // Get the first task (oldest priority or oldest open)
            if let firstTask = sortedTasks.first {
                selectedTask = TaskInfo(
                    title: firstTask.title,
                    uuid: firstTask.uuid.uuidString,
                    state: firstTask.state
                )
            }
        }

        return (availability, selectedQuadrant, selectedTask)
    }
}

// MARK: - Widget Entry View

struct GetMeATaskEntryView: View {
    var entry: GetMeATaskEntry

    var body: some View {
        ZStack {
            Color.orange
                .ignoresSafeArea()

            if let selectedTask = entry.selectedTask {
                taskDisplayView(task: selectedTask, quadrant: entry.selectedQuadrant)
            } else {
                eemGridView
            }
        }
    }

    @ViewBuilder
    private var eemGridView: some View {
        VStack(spacing: 8) {
            Text("Get me a Task")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.bottom, 4)

            // 2x2 Energy-Effort Matrix Grid
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    quadrantButton(.highEnergyBigTask)
                    quadrantButton(.lowEnergyBigTask)
                }
                HStack(spacing: 4) {
                    quadrantButton(.highEnergySmallTask)
                    quadrantButton(.lowEnergySmallTask)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @ViewBuilder
    private func quadrantButton(_ quadrant: EnergyEffortQuadrant) -> some View {
        let isAvailable = entry.quadrantAvailability[quadrant] ?? false

        Button(intent: SelectQuadrantIntent(quadrant: quadrant)) {
            VStack(spacing: 4) {
                Image(systemName: quadrant.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isAvailable ? .white : .gray)
                Text(quadrant.name)
                    .font(.caption2)
                    .foregroundStyle(isAvailable ? .white : .gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isAvailable ? quadrant.color.opacity(0.8) : Color.gray.opacity(0.3))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
    }

    @ViewBuilder
    private func taskDisplayView(task: TaskInfo, quadrant: EnergyEffortQuadrant?) -> some View {
        Link(destination: URL(string: "three-daily-goals://task/\(task.uuid)")!) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let quadrant = quadrant {
                        Image(systemName: quadrant.icon)
                            .foregroundStyle(quadrant.color)
                        Text(quadrant.name)
                            .font(.caption)
                            .foregroundStyle(.white)
                    }

                    // Show priority badge if it's a priority task
                    if task.state == .priority {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }

                    Spacer()
                    Button(intent: ClearSelectionIntent()) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }

                Text(task.title)
                    .font(.body)
                    .foregroundStyle(.white)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - App Intents

struct SelectQuadrantIntent: AppIntent {
    static let title: LocalizedStringResource = "Select Quadrant"

    @Parameter(title: "Quadrant")
    var quadrant: EnergyEffortQuadrant

    init(quadrant: EnergyEffortQuadrant) {
        self.quadrant = quadrant
    }

    init() {
        self.quadrant = .highEnergyBigTask
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // Store selected quadrant in CloudPreferences
        let preferences = CloudPreferences(testData: false, timeProvider: RealTimeProvider())
        preferences.setSelectedQuadrant(quadrant.rawValue)
        return .result()
    }
}

struct ClearSelectionIntent: AppIntent {
    static let title: LocalizedStringResource = "Clear Selection"

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        // Clear selected quadrant from CloudPreferences
        let preferences = CloudPreferences(testData: false, timeProvider: RealTimeProvider())
        preferences.clearSelectedQuadrant()
        return .result()
    }
}

// MARK: - Widget Configuration

struct GetMeATaskWidget: Widget {
    let kind: String = "GetMeATaskWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: GetMeATaskProvider()
        ) { entry in
            GetMeATaskEntryView(entry: entry)
                .containerBackground(Color.orange, for: .widget)
        }
        .configurationDisplayName("Get me a Task")
        .description("Select an Energy-Effort quadrant to get your next task")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    GetMeATaskWidget()
} timeline: {
    GetMeATaskEntry(
        date: .now,
        configuration: ConfigurationAppIntent(),
        quadrantAvailability: [
            .highEnergyBigTask: true,
            .lowEnergyBigTask: true,
            .highEnergySmallTask: false,
            .lowEnergySmallTask: true
        ],
        selectedQuadrant: nil,
        selectedTask: nil
    )
}
