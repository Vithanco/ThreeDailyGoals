//
//  ListView.swift
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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(TimeProviderWrapper.self) var timeProviderWrapper: TimeProviderWrapper
    let whichList: TaskItemState?

    init(whichList: TaskItemState? = nil) {
        self.whichList = whichList
    }

    var list: TaskItemState {
        return whichList ?? uiState.whichList
    }
    
    // Adaptive background color for tag container
    private var tagContainerBackground: Color {
        colorScheme == .dark ? Color.neutral700 : Color.neutral300
    }
    
    // Adaptive border color for tag container
    private var tagContainerBorder: Color {
        colorScheme == .dark ? Color.neutral600 : Color.neutral200
    }
    
    // Enhanced list background for better task box visibility
    private var listBackground: Color {
        colorScheme == .dark ? Color.neutral800.opacity(0.3) : Color.neutral50.opacity(0.8)
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
            .background(listBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorScheme == .dark ? Color.neutral700 : Color.neutral200, lineWidth: 1)
            )
            .shadow(color: colorScheme == .dark ? .black.opacity(0.1) : .black.opacity(0.05), radius: 2, x: 0, y: 1)
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
                                isSelected ? selectedTagStyle(accentColor: list.color) : missingTagStyle)
                    }
                )
                .frame(maxWidth: 400, minHeight: 30, maxHeight: 80)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tagContainerBackground)
                        .shadow(
                            color: colorScheme == .dark ? .black.opacity(0.15) : .black.opacity(0.08),
                            radius: 3,
                            x: 0,
                            y: 2
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(tagContainerBorder, lineWidth: 1.0)
                )
            }

        }
    }
}

#Preview {
    var appComp = setupApp(isTesting: true)
    ListView(whichList: .dead)
        .environment(appComp.uiState)
        .environment(appComp.dataManager)
        .environment(appComp.preferences)
}
