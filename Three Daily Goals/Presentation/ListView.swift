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
    @Environment(TaskManagerViewModel.self) private var model
    @State var whichList: TaskItemState?

    init(whichList: TaskItemState? = nil) {
        self.whichList = whichList
    }

    var list: TaskItemState {
        return whichList ?? (uiState.whichList == .priority ? .open : uiState.whichList)
    }

    var body: some View {
        let filterFunc: (TaskItem) -> Bool =
            uiState.selectedTags.isEmpty
            ? { _ in true } : { $0.tags.contains(where: uiState.selectedTags.contains) }
        let itemList = dataManager.list(which: list).filter(filterFunc)
        let headers = list.subHeaders
        VStack {
            SimpleListView(
                itemList: itemList, headers: headers, showHeaders: list != .priority, section: list.section,
                id: list.getListAccessibilityIdentifier
            )
            .frame(minHeight: 145, maxHeight: .infinity)
            .background(Color.background)
            .dropDestination(for: String.self) {
                items, _ in
                for item in items.compactMap({ dataManager.findTask(withUuidString: $0) }) {
                    dataManager.move(task: item, to: list)
                }
                return true
            }
            Spacer()
            let tags = dataManager.list(which: whichList ?? uiState.whichList).tags.asArray
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
                ).frame(maxWidth: 300, idealHeight: 15, maxHeight: 50).background(Color.background).padding(
                    5)
            }

        }
    }
}

#Preview {
    ListView(whichList: .dead)
        .environment(UIStateManager.testManager())
        .environment(DataManager.testManager())
        .environment(dummyPreferences())
        .environment(dummyViewModel())
}
