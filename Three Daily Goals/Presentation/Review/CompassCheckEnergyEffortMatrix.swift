//
//  CompassCheckEnergyEffortMatrix.swift
//  Three Daily Goals
//
//  Created by Claude Code on 2025-12-02.
//

import SwiftUI
import tdgCoreMain
import tdgCoreWidget

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
        let now = timeProviderWrapper.timeProvider.now
        let cutoffDate = Calendar.current.date(byAdding: .hour, value: -hoursBeforeReadyForClassification, to: now) ?? now

        return dataManager.allTasks.filter { task in
            task.isActive
            && !task.hasCompleteEnergyEffortTags
            && categorizedTasks[task.uuid] == nil
            && task.created < cutoffDate  // Only show tasks created long enough ago for classification
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
                Text("Tap a quadrant to categorize the top task")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(categorizedCount) of \(totalCount) tasks categorized")
                    .font(.caption)
                    .foregroundStyle(allTasksCategorized ? .green : .secondary)
            }
            .padding(.top, 8)

            // Grid with distributed axis labels (matching popover design)
            VStack(spacing: 8) {
                // Top label: Big Task
                VStack(spacing: 0) {
                    Text("Big")
                    Text("Task")
                }
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    // Left label: High Energy
                    VStack(spacing: 0) {
                        Text("High")
                        Text("Energy")
                    }
                    .font(.callout)
                    .fontWeight(.medium)
                    .frame(width: 70)
                    .foregroundStyle(.secondary)

                    // Interactive 2x2 grid (vertical=task size, horizontal=energy)
                    VStack(spacing: 8) {
                        // Top row: big tasks (high-energy -> low-energy)
                        HStack(spacing: 8) {
                            // Top-Left: highEnergyBigTask (high-energy, big-task) = Deep Work
                            QuadrantDropZone(
                                quadrant: .highEnergyBigTask,
                                taskCount: tasksForQuadrant(.highEnergyBigTask).count,
                                isHighlighted: !uncategorizedTasks.isEmpty,
                                onDrop: { taskId in handleDrop(taskId: taskId, quadrant: .highEnergyBigTask) },
                                onTap: { handleTap(quadrant: .highEnergyBigTask) }
                            )
                            // Top-Right: lowEnergyBigTask (low-energy, big-task) = Steady Progress
                            QuadrantDropZone(
                                quadrant: .lowEnergyBigTask,
                                taskCount: tasksForQuadrant(.lowEnergyBigTask).count,
                                isHighlighted: !uncategorizedTasks.isEmpty,
                                onDrop: { taskId in handleDrop(taskId: taskId, quadrant: .lowEnergyBigTask) },
                                onTap: { handleTap(quadrant: .lowEnergyBigTask) }
                            )
                        }
                        // Bottom row: small tasks (high-energy -> low-energy)
                        HStack(spacing: 8) {
                            // Bottom-Left: highEnergySmallTask (high-energy, small-task) = Sprint Tasks
                            QuadrantDropZone(
                                quadrant: .highEnergySmallTask,
                                taskCount: tasksForQuadrant(.highEnergySmallTask).count,
                                isHighlighted: !uncategorizedTasks.isEmpty,
                                onDrop: { taskId in handleDrop(taskId: taskId, quadrant: .highEnergySmallTask) },
                                onTap: { handleTap(quadrant: .highEnergySmallTask) }
                            )
                            // Bottom-Right: lowEnergySmallTask (low-energy, small-task) = Easy Wins
                            QuadrantDropZone(
                                quadrant: .lowEnergySmallTask,
                                taskCount: tasksForQuadrant(.lowEnergySmallTask).count,
                                isHighlighted: !uncategorizedTasks.isEmpty,
                                onDrop: { taskId in handleDrop(taskId: taskId, quadrant: .lowEnergySmallTask) },
                                onTap: { handleTap(quadrant: .lowEnergySmallTask) }
                            )
                        }
                    }

                    // Right label: Low Energy
                    VStack(spacing: 0) {
                        Text("Low")
                        Text("Energy")
                    }
                    .font(.callout)
                    .fontWeight(.medium)
                    .frame(width: 70)
                    .foregroundStyle(.secondary)
                }

                // Bottom label: Small Task
                VStack(spacing: 0) {
                    Text("Small")
                    Text("Task")
                }
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            // Uncategorized Tasks
            if !uncategorizedTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.vertical, 4)

                    Text("Uncategorized Tasks - Tap a quadrant above to categorize the top task")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(uncategorizedTasks) { task in
                            TaskAsLine(item: task)
                                .padding(.vertical, 2)
                        }
                    }
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

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Quadrant Icon
                Image(systemName: quadrant.icon)
                    .font(.title3)
                    .foregroundStyle(.white)

                // Quadrant Name
                Text(quadrant.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                // Task Count (if any)
                if taskCount > 0 {
                    Text("\(taskCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.white.opacity(0.25))
                        .clipShape(.rect(cornerRadius: 6))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .padding(8)
        }
        .buttonStyle(.plain)
        .background(quadrant.color.opacity(0.85))
        .clipShape(.rect(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHighlighted ? Color.white : Color.clear, lineWidth: 3)
        )
        .dropDestination(for: String.self) { items, _ in
            for item in items {
                onDrop(item)
            }
            return true
        }
        .help(quadrant.description)
    }
}


#Preview {
    let appComponents = setupApp(isTesting: true)
    CompassCheckEnergyEffortMatrix()
        .environment(appComponents.dataManager)
        .environment(appComponents.timeProviderWrapper)
}
