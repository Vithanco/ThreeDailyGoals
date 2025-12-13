//
//  LeftSideView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftData
import SwiftUI
import tdgCoreMain

struct LeftSideView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(CloudPreferences.self) private var preferences
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \TaskItem.changed) private var allTasks: [TaskItem]
    @State private var selectedTags: [String] = []  // <-- State property for TagFilterView

    // You can replace this with your dynamic tags source
    private var allAvailableTags: [String] {
        // Example: collect all tags present in your tasks dynamically
        Set(
            allTasks.flatMap { task in
                #if swift(>=5.9)
                    task.tags
                #else
                    // If using new schema, may be something like task.allTagsString.split(separator: ",")
                    task._tags
                #endif
            }
        ).sorted()
    }

    private var priorityTasks: [TaskItem] {
        allTasks.filter { $0.state == .priority }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Streak view for both iOS and macOS (moved above Today's Goals)
            FullStreakView().frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            #if os(iOS)
                if isLargeDevice {
                    HStack {
                        Spacer()
                        Circle().frame(width: 10).foregroundStyle(Color.priority).help(
                            "Drop Target, as iOS has an issue. Will be hopefully removed with next version of iOS."
                        )
                        Spacer()
                    }
                    .dropDestination(for: String.self) { items, location in
                        Task { @MainActor in
                            for item in items.compactMap({ dataManager.findTask(withUuidString: $0) }) {
                                dataManager.moveWithPriorityTracking(task: item, to: .open)
                            }
                        }
                        return true
                    }
                }
            #endif

            // Priority list (main content area) - removed background styling
            SimpleListView(
                color: .priority,
                itemList: priorityTasks,
                headers: TaskItemState.priority.subHeaders,
                showHeaders: false,
                section: TaskItemState.priority.section,
                id: TaskItemState.priority.getListAccessibilityIdentifier
            )
            .dropDestination(for: String.self) { items, _ in
                Task { @MainActor in
                    withAnimation {
                        for itemId in items {
                            if let item = dataManager.findTask(withUuidString: itemId) {
                                dataManager.moveWithPriorityTracking(task: item, to: .priority)
                            }
                        }
                    }
                }
                return true
            }
            .frame(minHeight: 145, maxHeight: .infinity)

            Spacer()

            let paddingVertical = isLargeDevice ? 16.0 : 4.0

            // List selector section
            VStack(spacing: 8) {
                // Section header
                HStack {
                    Text("Lists")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Spacer()
                }

                // List items
                VStack(spacing: 8) {
                    LinkToList(whichList: .open)
                    LinkToList(whichList: .pendingResponse)
                    LinkToList(whichList: .closed)
                    LinkToList(whichList: .dead)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, paddingVertical)
            //   .background(preferences.isProductionEnvironment ? Color.clear : Color.yellow.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(macOS)
            .frame(minWidth: 350, idealWidth: 500, maxWidth: 1000)  // Ensure minimum width for comfortable reading
        #endif
    }
}

//#Preview {
//    LeftSideView()
//}
