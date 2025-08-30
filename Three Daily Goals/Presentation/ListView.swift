//
//  TaskListView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI
import TagKit

extension ListHeader {
    var asText: Text {
        Text("Last updated: \(name)").font(.callout)
    }
}

struct ListView: View {
    @Environment(UIStateManager.self) private var uiState
    @Environment(DataManager.self) private var dataManager
    @Environment(CloudPreferences.self) private var preferences
    let whichList: TaskItemState?

    init(whichList: TaskItemState? = nil) {
        self.whichList = whichList
    }

    var list: TaskItemState {
        return whichList ?? uiState.whichList
    }

    var body: some View {
        let filterFunc: (TaskItem) -> Bool =
            uiState.selectedTags.isEmpty
            ? { _ in true } : { $0.tags.contains(where: uiState.selectedTags.contains) }
        let itemList = dataManager.list(which: list).filter(filterFunc)
        let headers = list.subHeaders
        VStack {
            SimpleListView(
                color: list.color,
                itemList: itemList, headers: headers, showHeaders: list != .priority, section: list.section,
                id: list.getListAccessibilityIdentifier
            )
            .frame(minHeight: 145, maxHeight: .infinity)
            .background(Color.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .dropDestination(for: String.self) {
                items, _ in
                for item in items.compactMap({ dataManager.findTask(withUuidString: $0) }) {
                    dataManager.move(task: item, to: list)
                }
                return true
            }
            Spacer()
            let taskItems: [TaskItem] = dataManager.list(which: list)
            let tags = Set(taskItems.flatMap { $0.tags }).asArray
            if !tags.isEmpty {
                TagEditList(
                    tags: Binding(
                        get: { uiState.selectedTags },
                        set: { uiState.selectedTags = $0 }
                    ),
                    additionalTags: tags,
                    container: .vstack,
                    horizontalSpacing: 1,
                    verticalSpacing: 1,
                    tagView: { text, isSelected in
                        TagCapsule(text)
                            .tagCapsuleStyle(
                                isSelected ? selectedTagStyle(accentColor: preferences.accentColor) : missingTagStyle)
                    }
                )
                .frame(maxWidth: .infinity, idealHeight: 15, maxHeight: 50)
                .padding(.horizontal, 0)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.background)
                        .shadow(
                            color: Color.black.opacity(0.03),
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.neutral200, lineWidth: 0.5)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

        }
    }
}

#Preview {
    ListView(whichList: .dead)
        .environment(UIStateManager.testManager())
        .environment(DataManager.testManager())
        .environment(dummyPreferences())
}
