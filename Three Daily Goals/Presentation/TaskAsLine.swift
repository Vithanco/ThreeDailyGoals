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
    @Environment(\.colorScheme) private var colorScheme
    let item: TaskItem

    var accentColor: Color {
        return preferences.accentColor
    }

    var text: some View {
        return Text(item.title.trimmingCharacters(in: .whitespacesAndNewlines))
            .strikethrough(item.isClosed, color: accentColor)
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

    var body: some View {
        HStack {
            text
            Spacer()
            if hasDue {
                Text(item.due!.timeRemaining).italic().foregroundStyle(Color.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(cardBackground)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(cardBorder, lineWidth: 0.5)
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
    TaskAsLine(item: DataManager.testManager().items.first!)
        .environment(DataManager.testManager())
        .environment(dummyPreferences())
        .environment(UIStateManager())
}
