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
    @Environment(TaskManagerViewModel.self) private var model
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

    var body: some View {
        HStack {

            text
            Spacer()
            if hasDue {
                Text(item.due!.timeRemaining).italic().foregroundStyle(Color.gray)
            }
        }
        .contentShape(Rectangle())
        #if os(macOS)
            .draggable(item.id)
        #endif
        .swipeActions(edge: .leading) {

            if item.canBeMovedToOpen {
                model.openButton(item: item)
            }
            if item.canBeMadePriority {
                model.priorityButton(item: item)
            }
        }
        .swipeActions(edge: .trailing) {
            if item.canBeMovedToPendingResponse {
                model.waitForResponseButton(item: item)
            }
            if item.canBeClosed {
                model.killButton(item: item)
                model.closeButton(item: item)
            }
            if item.canBeDeleted {
                model.deleteButton(item: item)
            }
        }
    }
}

#Preview {
    TaskAsLine(item: DataManager.testManager().items.first!)
        .environment(DataManager.testManager())
        .environment(dummyPreferences())
        .environment(dummyViewModel())
}
