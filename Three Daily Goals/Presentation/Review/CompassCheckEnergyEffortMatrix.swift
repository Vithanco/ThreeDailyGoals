//
//  CompassCheckEnergyEffortMatrix.swift
//  Three Daily Goals
//
//  Created by Claude Code on 2025-12-02.
//

import SwiftUI
import tdgCoreMain

public struct CompassCheckEnergyEffortMatrix: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(TimeProviderWrapper.self) private var timeProviderWrapper

    public var body: some View {
        EnergyEffortMatrixView()
    }
}

// MARK: - Unified Implementation (Drag & Drop)

@MainActor
struct EnergyEffortMatrixView: View {
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
                Text("Drag tasks into quadrants or tap a quadrant to move the top task")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(categorizedCount) of \(totalCount) tasks categorized")
                    .font(.caption)
                    .foregroundStyle(allTasksCategorized ? .green : .secondary)
            }
            .padding(.top, 8)

            // EnergyEffort Matrix Grid
            HStack(spacing: 12) {
                // Left Column
                VStack(spacing: 12) {
                    // Q1: Urgent & Important
                    QuadrantDropZone(
                        quadrant: .urgentImportant,
                        taskCount: tasksForQuadrant(.urgentImportant).count,
                        isHighlighted: !uncategorizedTasks.isEmpty,
                        onDrop: { taskId in handleDrop(taskId: taskId, quadrant: .urgentImportant) },
                        onTap: { handleTap(quadrant: .urgentImportant) }
                    )

                    // Q3: Urgent & Not Important
                    QuadrantDropZone(
                        quadrant: .urgentNotImportant,
                        taskCount: tasksForQuadrant(.urgentNotImportant).count,
                        isHighlighted: !uncategorizedTasks.isEmpty,
                        onDrop: { taskId in handleDrop(taskId: taskId, quadrant: .urgentNotImportant) },
                        onTap: { handleTap(quadrant: .urgentNotImportant) }
                    )
                }

                // Right Column
                VStack(spacing: 12) {
                    // Q2: Not Urgent & Important
                    QuadrantDropZone(
                        quadrant: .notUrgentImportant,
                        taskCount: tasksForQuadrant(.notUrgentImportant).count,
                        isHighlighted: !uncategorizedTasks.isEmpty,
                        onDrop: { taskId in handleDrop(taskId: taskId, quadrant: .notUrgentImportant) },
                        onTap: { handleTap(quadrant: .notUrgentImportant) }
                    )

                    // Q4: Not Urgent & Not Important
                    QuadrantDropZone(
                        quadrant: .notUrgentNotImportant,
                        taskCount: tasksForQuadrant(.notUrgentNotImportant).count,
                        isHighlighted: !uncategorizedTasks.isEmpty,
                        onDrop: { taskId in handleDrop(taskId: taskId, quadrant: .notUrgentNotImportant) },
                        onTap: { handleTap(quadrant: .notUrgentNotImportant) }
                    )
                }
            }
            .padding(.horizontal)

            // Uncategorized Tasks
            if !uncategorizedTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Uncategorized Tasks - Drag to categorize")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    List {
                        ForEach(uncategorizedTasks) { task in
                            TaskAsLine(item: task)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .frame(maxHeight: 200)
                }
                .padding(.horizontal)
            }
        }
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

        // Apply tags immediately
        task.applyEnergyEffortQuadrant(quadrant)
        dataManager.save()
    }

    private func handleTap(quadrant: EnergyEffortQuadrant) {
        // Move the first uncategorized task to the tapped quadrant
        guard let task = uncategorizedTasks.first else { return }

        withAnimation {
            categorizedTasks[task.uuid] = quadrant
        }

        // Apply tags immediately
        task.applyEnergyEffortQuadrant(quadrant)
        dataManager.save()
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
    let taskCount: Int
    let isHighlighted: Bool
    let onDrop: (String) -> Void
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var quadrantBackground: Color {
        if isHighlighted {
            return quadrant.color.opacity(0.15)
        }
        return colorScheme == .dark ? Color.neutral800 : Color.neutral100
    }

    private var quadrantBorder: Color {
        if isHighlighted {
            return quadrant.color
        }
        return quadrant.color.opacity(0.5)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
            // Quadrant Icon
            Image(systemName: quadrant.icon)
                .font(.largeTitle)
                .foregroundStyle(quadrant.color)

            // Quadrant Name
            Text(quadrant.name)
                .font(.headline)
                .foregroundStyle(quadrant.color)
                .multilineTextAlignment(.center)

            // Quadrant Description
            Text(quadrant.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Task Count
            if taskCount > 0 {
                Text("\(taskCount) task\(taskCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(quadrant.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(quadrant.color.opacity(0.2))
                    .clipShape(.rect(cornerRadius: 12))
            }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .buttonStyle(.plain)
        .background(quadrantBackground)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(quadrantBorder, lineWidth: isHighlighted ? 3 : 2)
        )
        .dropDestination(for: String.self) { items, _ in
            for item in items {
                onDrop(item)
            }
            return true
        }
    }
}


#Preview {
    let appComponents = setupApp(isTesting: true)
    CompassCheckEnergyEffortMatrix()
        .environment(appComponents.dataManager)
        .environment(appComponents.timeProviderWrapper)
}
