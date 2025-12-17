//
//  TaskAsLine.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 24/12/2023.
//

import SwiftUI
import tdgCoreMain

struct TaskAsLine: View {
    @Environment(CloudPreferences.self) private var preferences
    @Environment(DataManager.self) private var dataManager
    @Environment(UIStateManager.self) private var uiState
    @Environment(TimeProviderWrapper.self) private var timeProviderWrapper
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var item: TaskItem

    var text: some View {
        return Text(item.title.trimmingCharacters(in: .whitespacesAndNewlines))
        //  .strikethrough(item.isClosed, color: .closed)
    }

    var hasDue: Bool {
        return item.due != nil && item.isOpenOrPriority
    }

    // Adaptive background color for light/dark mode
    private var cardBackground: Color {
        colorScheme == .dark ? Color.neutral800 : Color.neutral50
    }

    // Adaptive border color for light/dark mode
    private var cardBorder: Color {
        colorScheme == .dark ? Color.neutral700 : Color.neutral200
    }

    // Enhanced shadow color for better visibility
    private var cardShadow: Color {
        colorScheme == .dark ? .black.opacity(0.15) : .black.opacity(0.15)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Energy-Effort Matrix quadrant indicator
            EnergyEffortQuadrantIndicator(task: item)

            text
            Spacer()
            if hasDue, let dueDate = item.due {
                Text(timeProviderWrapper.timeProvider.timeRemaining(for: dueDate)).italic().foregroundStyle(Color.gray)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(cardBackground)
        .clipShape(.rect(cornerRadius: 10))
        .shadow(color: cardShadow, radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(cardBorder, lineWidth: 1.0)
        )
        .contentShape(Rectangle())
        .draggable(item.id) {
            // Provide a simple preview
            Text(item.title)
                .padding(8)
                .background(Color.accentColor.opacity(0.4))
                .clipShape(.rect(cornerRadius: 8))
        }
        #if os(macOS)
        .contextMenu {
            if item.canBeMovedToOpen {
                dataManager.openButton(item: item)
            }
            if item.canBeMadePriority {
                dataManager.priorityButton(item: item)
            }
            if item.canBeMovedToPendingResponse {
                dataManager.waitForResponseButton(item: item)
            }
            if item.canBeClosed {
                dataManager.closeButton(item: item)
                dataManager.killButton(item: item)
            }
            if item.canBeDeleted {
                Divider()
                dataManager.deleteButton(item: item, uiState: uiState)
            }
        }
        #else
        .swipeActions(edge: .leading) {
            if item.canBeMovedToOpen {
                dataManager.openButton(item: item).tint(TaskItemState.open.color)
            }
            if item.canBeMadePriority {
                dataManager.priorityButton(item: item).tint(TaskItemState.priority.color)
            }
        }
        .swipeActions(edge: .trailing) {
            if item.canBeMovedToPendingResponse {
                dataManager.waitForResponseButton(item: item).tint(TaskItemState.pendingResponse.color)
            }
            if item.canBeClosed {
                dataManager.killButton(item: item).tint(TaskItemState.dead.color)
                dataManager.closeButton(item: item).tint(TaskItemState.closed.color)
            }
            if item.canBeDeleted {
                dataManager.deleteButton(item: item, uiState: uiState)
            }
        }
        #endif
    }
}

// MARK: - Energy-Effort Matrix Quadrant Indicator

/// A small 2x2 grid indicator showing the Energy-Effort Matrix quadrant for a task
/// - Shows all 4 quadrants with only the active one colored, others grayed out
/// - If task has incomplete tags (missing energy or effort), all quadrants are grayed out
struct EnergyEffortQuadrantIndicator: View {
    let task: TaskItem
    let size: CGFloat = 20  // Total size of the 2x2 grid

    private var activeQuadrant: EnergyEffortQuadrant? {
        EnergyEffortQuadrant.from(task: task)
    }

    private var hasCompleteMatrixTags: Bool {
        task.hasCompleteEnergyEffortTags
    }

    // Size of each individual quadrant square
    private var quadrantSize: CGFloat {
        (size - 2) / 2  // Subtract 2 for the 1pt gaps between squares
    }

    var body: some View {
        VStack(spacing: 1) {
            // Top row: high-energy tasks
            HStack(spacing: 1) {
                // Top-Left: urgentImportant (high-energy, big-task)
                QuadrantSquare(
                    quadrant: .urgentImportant,
                    isActive: activeQuadrant == .urgentImportant,
                    hasCompleteTags: hasCompleteMatrixTags,
                    size: quadrantSize
                )

                // Top-Right: urgentNotImportant (high-energy, small-task)
                QuadrantSquare(
                    quadrant: .urgentNotImportant,
                    isActive: activeQuadrant == .urgentNotImportant,
                    hasCompleteTags: hasCompleteMatrixTags,
                    size: quadrantSize
                )
            }

            // Bottom row: low-energy tasks
            HStack(spacing: 1) {
                // Bottom-Left: notUrgentImportant (low-energy, big-task)
                QuadrantSquare(
                    quadrant: .notUrgentImportant,
                    isActive: activeQuadrant == .notUrgentImportant,
                    hasCompleteTags: hasCompleteMatrixTags,
                    size: quadrantSize
                )

                // Bottom-Right: notUrgentNotImportant (low-energy, small-task)
                QuadrantSquare(
                    quadrant: .notUrgentNotImportant,
                    isActive: activeQuadrant == .notUrgentNotImportant,
                    hasCompleteTags: hasCompleteMatrixTags,
                    size: quadrantSize
                )
            }
        }
        .frame(width: size, height: size)
        .opacity(hasCompleteMatrixTags ? 0.8 : 0)
    }
}

/// A single square in the 2x2 quadrant grid
private struct QuadrantSquare: View {
    let quadrant: EnergyEffortQuadrant
    let isActive: Bool
    let hasCompleteTags: Bool
    let size: CGFloat

    private var fillColor: Color {
        if !hasCompleteTags {
            // If task doesn't have complete tags, all quadrants are gray
            return Color.gray.opacity(0.2)
        } else if isActive {
            // Active quadrant shows its designated color
            return quadrant.color
        } else {
            // Inactive quadrants are grayed out
            return Color.gray.opacity(0.2)
        }
    }

    var body: some View {
        Rectangle()
            .fill(fillColor)
            .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview {
    let appComp = setupApp(isTesting: true)
    TaskAsLine(item: appComp.dataManager.allTasks.first!)
        .environment(appComp.uiState)
        .environment(appComp.dataManager)
        .environment(appComp.preferences)
}
