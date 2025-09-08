//
//  TaskAsLine.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 24/12/2023.
//

import SwiftUI

struct TaskAsLine: View {
    @Environment(CloudPreferences.self) private var preferences
    @Environment(DataManager.self) private var dataManager
    @Environment(UIStateManager.self) private var uiState
    @Environment(TimeProviderWrapper.self) private var timeProviderWrapper
    @Environment(\.colorScheme) private var colorScheme
    let item: TaskItem

    var text: some View {
        return Text(item.title.trimmingCharacters(in: .whitespacesAndNewlines))
          //  .strikethrough(item.isClosed, color: .closed)
            .draggable(item.id)
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
        HStack {
            text
            Spacer()
            if hasDue, let dueDate = item.due {
                Text(timeProviderWrapper.timeProvider.timeRemaining(for: dueDate)).italic().foregroundStyle(Color.gray)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(cardBackground)
        .cornerRadius(10)
        .shadow(color: cardShadow, radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(cardBorder, lineWidth: 1.0)
        )
        .contentShape(Rectangle())
        #if os(macOS)
            .draggable(item.id)
        #endif
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
    }
}

#Preview {
    let appComp = setupApp(isTesting: true)
    TaskAsLine(item: appComp.dataManager.items.first!)
            .environment(appComp.uiState)
            .environment(appComp.dataManager)
            .environment(appComp.preferences)
}
