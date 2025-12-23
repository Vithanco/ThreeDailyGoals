//
//  ListView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftData
import SwiftUI
import tdgCoreMain

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
    let whichList: TaskItemState
    let enableNavigation: Bool

    @Query(sort: \TaskItem.changed) private var allTasks: [TaskItem]

    init(whichList: TaskItemState, enableNavigation: Bool = true) {
        self.whichList = whichList
        self.enableNavigation = enableNavigation
    }

    private var tasks: [TaskItem] {
        let filtered = allTasks.filter { $0.state == whichList }

        // Sort by changed date, reverse for closed/dead
        if whichList == .closed || whichList == .dead {
            return filtered.sorted { $0.changed > $1.changed }
        }
        return filtered
    }

    var list: TaskItemState {
        return whichList
    }

    // Adaptive background color for tag container
    private var tagContainerBackground: Color {
        colorScheme == .dark ? Color.neutral700 : Color.neutral300
    }

    // Adaptive border color for tag container
    private var tagContainerBorder: Color {
        colorScheme == .dark ? Color.neutral600 : Color.neutral200
    }

    // Enhanced list background with subtle tint toward list color
    private var listBackground: some View {
        ZStack {
            // Base neutral background
            if colorScheme == .dark {
                Color.neutral800.opacity(0.3)
            } else {
                Color.neutral200.opacity(0.9)
            }

            // Subtle color tint overlay
            whichList.color.opacity(0.02)
        }
    }

    private var filteredTasks: [TaskItem] {
        if uiState.selectedTags.isEmpty {
            return tasks
        }
        return tasks.filter { $0.tags.contains(where: uiState.selectedTags.contains) }
    }

    var body: some View {
        VStack {
            SimpleListView(
                color: list.color,
                itemList: filteredTasks, headers: list.subHeaders, showHeaders: list != .priority,
                section: list.section,
                id: list.getListAccessibilityIdentifier,
                enableNavigation: enableNavigation
            )
            .frame(minHeight: 145, maxHeight: .infinity)
            .background(listBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorScheme == .dark ? Color.neutral700 : Color.neutral200, lineWidth: 1)
            )
            .shadow(color: colorScheme == .dark ? .black.opacity(0.1) : .black.opacity(0.05), radius: 2, x: 0, y: 1)
            .dropDestination(for: String.self) { items, _ in
                Task { @MainActor in
                    withAnimation {
                        for item in items.compactMap({ dataManager.findTask(withUuidString: $0) }) {
                            dataManager.move(task: item, to: list)
                        }
                    }
                }
                return true
            }
            Spacer()
            let tags = Set(tasks.flatMap { $0.tags }).asArray
            if !tags.isEmpty {
                TagFilterView(
                    tags: tags,
                    selectedTags: Binding(
                        get: { uiState.selectedTags },
                        set: { uiState.selectedTags = $0 }
                    ),
                    listColor: list.color
                )
            }

        }
    }
}

#Preview {
    let appComp = setupApp(isTesting: true)
    ListView(whichList: .dead)
        .environment(appComp.uiState)
        .environment(appComp.dataManager)
        .environment(appComp.preferences)
}
