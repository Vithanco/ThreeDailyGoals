//
//  CompassCheckEisenhowerMatrix.swift
//  Three Daily Goals
//
//  Created by Claude Code on 2025-12-02.
//

import SwiftUI
import tdgCoreMain

public struct CompassCheckEisenhowerMatrix: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(TimeProviderWrapper.self) private var timeProviderWrapper

    public var body: some View {
        #if os(macOS)
        EisenhowerMatrixMacOSView()
        #else
        EisenhowerMatrixiOSView()
        #endif
    }
}

// MARK: - macOS Implementation (Drag & Drop)

@MainActor
struct EisenhowerMatrixMacOSView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(TimeProviderWrapper.self) private var timeProviderWrapper
    @Environment(\.colorScheme) private var colorScheme

    @State private var categorizedTasks: [UUID: EnergyEffortQuadrant] = [:]

    private var uncategorizedTasks: [TaskItem] {
        dataManager.allTasks.filter { task in
            task.isActive && !task.hasCompleteEnergyEffortTags && categorizedTasks[task.uuid] == nil
        }
    }

    private var categorizedCount: Int {
        return categorizedTasks.count
    }

    private var totalCount: Int {
        return uncategorizedTasks.count + categorizedCount
    }

    private var allTasksCategorized: Bool {
        return uncategorizedTasks.isEmpty
    }

    // Adaptive colors
    private var quadrantBackground: Color {
        colorScheme == .dark ? Color.neutral800 : Color.neutral50
    }

    private var quadrantBorder: Color {
        colorScheme == .dark ? Color.neutral700 : Color.neutral200
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header
            VStack(spacing: 6) {
                Text("Energy-Effort Matrix")
                    .font(.title2)
                    .foregroundStyle(Color.priority)
                Text("Categorize tasks by energy required and task size")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Inspired by the Eisenhower Matrix, adapted for execution planning")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .italic()
                Text("Drag tasks from below into quadrants (or use swipe actions)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(categorizedCount) of \(totalCount) tasks categorized")
                    .font(.caption)
                    .foregroundStyle(allTasksCategorized ? .green : .secondary)
            }
            .padding(.top, 8)

            // Eisenhower Matrix Grid
            HStack(spacing: 12) {
                // Left Column
                VStack(spacing: 12) {
                    // Q1: Urgent & Important
                    QuadrantDropZone(
                        quadrant: .urgentImportant,
                        tasks: tasksForQuadrant(.urgentImportant),
                        onDrop: { taskId in handleDrop(taskId: taskId, quadrant: .urgentImportant) }
                    )

                    // Q3: Urgent & Not Important
                    QuadrantDropZone(
                        quadrant: .urgentNotImportant,
                        tasks: tasksForQuadrant(.urgentNotImportant),
                        onDrop: { taskId in handleDrop(taskId: taskId, quadrant: .urgentNotImportant) }
                    )
                }

                // Right Column
                VStack(spacing: 12) {
                    // Q2: Not Urgent & Important
                    QuadrantDropZone(
                        quadrant: .notUrgentImportant,
                        tasks: tasksForQuadrant(.notUrgentImportant),
                        onDrop: { taskId in handleDrop(taskId: taskId, quadrant: .notUrgentImportant) }
                    )

                    // Q4: Not Urgent & Not Important
                    QuadrantDropZone(
                        quadrant: .notUrgentNotImportant,
                        tasks: tasksForQuadrant(.notUrgentNotImportant),
                        onDrop: { taskId in handleDrop(taskId: taskId, quadrant: .notUrgentNotImportant) }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Uncategorized Tasks
            if !uncategorizedTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Uncategorized Tasks - Drag to categorize")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(uncategorizedTasks) { task in
                                TaskAsLine(item: task)
                            }
                        }
                        .padding(4)
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.horizontal)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onDisappear {
            applyCategorizationsToTasks()
        }
    }

    private func tasksForQuadrant(_ quadrant: EnergyEffortQuadrant) -> [TaskItem] {
        return categorizedTasks
            .filter { $0.value == quadrant }
            .compactMap { uuid, _ in
                dataManager.allTasks.first { $0.uuid == uuid }
            }
    }

    private func handleDrop(taskId: String, quadrant: EnergyEffortQuadrant) {
        guard let task = dataManager.findTask(withUuidString: taskId) else { return }

        withAnimation {
            categorizedTasks[task.uuid] = quadrant
        }
    }

    private func applyCategorizationsToTasks() {
        for (uuid, quadrant) in categorizedTasks {
            guard let task = dataManager.allTasks.first(where: { $0.uuid == uuid }) else { continue }

            // Apply quadrant tags
            task.applyEnergyEffortQuadrant(quadrant)
        }
        dataManager.save()
    }
}

// MARK: - Quadrant Drop Zone

struct QuadrantDropZone: View {
    let quadrant: EnergyEffortQuadrant
    let tasks: [TaskItem]
    let onDrop: (String) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var quadrantBackground: Color {
        colorScheme == .dark ? Color.neutral800 : Color.neutral100
    }

    private var quadrantBorder: Color {
        quadrant.color.opacity(0.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Quadrant Header
            HStack {
                Image(systemName: quadrant.icon)
                    .foregroundStyle(quadrant.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(quadrant.name)
                        .font(.headline)
                        .foregroundStyle(quadrant.color)
                    Text(quadrant.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(8)
            .background(quadrant.color.opacity(0.1))
            .cornerRadius(8)

            // Tasks in this quadrant
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(tasks) { task in
                        TaskAsLine(item: task)
                    }

                    if tasks.isEmpty {
                        Text("Drop tasks here")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    }
                }
                .padding(4)
            }
        }
        .padding(12)
        .background(quadrantBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(quadrantBorder, lineWidth: 2)
        )
        .dropDestination(for: String.self) { items, _ in
            for item in items {
                onDrop(item)
            }
            return true
        }
    }
}

// MARK: - iOS/iPadOS Implementation (Button Selection)

@MainActor
struct EisenhowerMatrixiOSView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(TimeProviderWrapper.self) private var timeProviderWrapper

    @State private var uncategorizedTasks: [TaskItem] = []
    @State private var currentTaskIndex: Int = 0
    @State private var selectedQuadrant: EnergyEffortQuadrant?

    private var currentTask: TaskItem? {
        guard currentTaskIndex < uncategorizedTasks.count else { return nil }
        return uncategorizedTasks[currentTaskIndex]
    }

    private var progress: String {
        guard !uncategorizedTasks.isEmpty else { return "All tasks categorized!" }
        return "\(currentTaskIndex + 1) of \(uncategorizedTasks.count)"
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Header
            VStack(spacing: 4) {
                Text("Energy-Effort Matrix")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Tap a quadrant to categorize")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(progress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let task = currentTask {
                // Quadrant Selection Grid
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        QuadrantButton(
                            quadrant: .urgentImportant,
                            isSelected: selectedQuadrant == .urgentImportant,
                            action: { selectQuadrant(.urgentImportant) }
                        )

                        QuadrantButton(
                            quadrant: .notUrgentImportant,
                            isSelected: selectedQuadrant == .notUrgentImportant,
                            action: { selectQuadrant(.notUrgentImportant) }
                        )
                    }

                    HStack(spacing: 12) {
                        QuadrantButton(
                            quadrant: .urgentNotImportant,
                            isSelected: selectedQuadrant == .urgentNotImportant,
                            action: { selectQuadrant(.urgentNotImportant) }
                        )

                        QuadrantButton(
                            quadrant: .notUrgentNotImportant,
                            isSelected: selectedQuadrant == .notUrgentNotImportant,
                            action: { selectQuadrant(.notUrgentNotImportant) }
                        )
                    }
                }
                .padding(.horizontal)

                // Current Task
                VStack(spacing: 8) {
                    Text("Categorize:")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    List {
                        TaskAsLine(item: task)
                    }
                    .listStyle(.plain)
                    .frame(height: 60)
                    .scrollDisabled(true)
                }
                .padding(.horizontal)

                Spacer()

                // Action Buttons
                HStack(spacing: 20) {
                    Button("Skip") {
                        skipTask()
                    }
                    .buttonStyle(.bordered)

                    Button("Next") {
                        nextTask()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedQuadrant == nil)
                }
                .padding()

                Spacer()
            } else {
                // All done
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)

                    Text("All tasks categorized!")
                        .font(.title2)
                        .fontWeight(.medium)

                    Text("You can continue to the next step.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadUncategorizedTasks()
        }
    }

    private func loadUncategorizedTasks() {
        uncategorizedTasks = dataManager.allTasks.filter { task in
            task.isActive && !task.hasCompleteEnergyEffortTags
        }
    }

    private func selectQuadrant(_ quadrant: EnergyEffortQuadrant) {
        selectedQuadrant = quadrant
        // Automatically proceed to next task after selection
        nextTask()
    }

    private func skipTask() {
        selectedQuadrant = nil
        currentTaskIndex += 1
    }

    private func nextTask() {
        guard let task = currentTask, let quadrant = selectedQuadrant else { return }

        // Apply categorization
        task.applyEnergyEffortQuadrant(quadrant)

        // Save and move to next
        dataManager.save()

        selectedQuadrant = nil
        currentTaskIndex += 1
    }
}

// MARK: - Quadrant Button (iOS)

struct QuadrantButton: View {
    let quadrant: EnergyEffortQuadrant
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: quadrant.icon)
                    .font(.title2)
                    .foregroundStyle(quadrant.color)

                VStack(spacing: 4) {
                    Text(quadrant.name)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(quadrant.description)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding()
            .background(isSelected ? quadrant.color : quadrant.color.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(quadrant.color, lineWidth: isSelected ? 3 : 1)
            )
        }
    }
}

#Preview {
    let appComponents = setupApp(isTesting: true)
    CompassCheckEisenhowerMatrix()
        .environment(appComponents.dataManager)
        .environment(appComponents.timeProviderWrapper)
}
