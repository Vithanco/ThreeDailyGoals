//
//  ReviewNextPriorities.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI
import tdgCoreMain

public struct CompassCheckNextPriorities: View {
    @Environment(CloudPreferences.self) private var preferences
    @Environment(DataManager.self) private var dataManager

    @State private var presentAlert = false
    @State private var newTaskName: String = ""

    public var body: some View {
        VStack {
            #if os(macOS)

                Text(
                    "Choose Next Priorities via drag'n'drop \(Image(systemName: "arrowshape.left.arrowshape.right.fill"))"
                ).font(.title2).foregroundStyle(Color.priority).multilineTextAlignment(.center)
                HStack {
                    SimpleListView(
                        color: .priority,
                        itemList: dataManager.list(which: .priority),
                        headers: TaskItemState.priority.subHeaders,
                        showHeaders: false,
                        section: TaskItemState.priority.section,
                        id: TaskItemState.priority.getListAccessibilityIdentifier
                    )
                    .frame(minHeight: 500)
                    .dropDestination(for: String.self) { items, _ in
                        Task { @MainActor in
                            withAnimation {
                                for item in items.compactMap({ dataManager.findTask(withUuidString: $0) }) {
                                    dataManager.move(task: item, to: .priority)
                                }
                            }
                        }
                        return true
                    }
                    SimpleListView(
                        color: .open,
                        itemList: dataManager.list(which: .open),
                        headers: TaskItemState.open.subHeaders,
                        showHeaders: true,
                        section: TaskItemState.open.section,
                        id: TaskItemState.open.getListAccessibilityIdentifier
                    )
                    .dropDestination(for: String.self) { items, _ in
                        Task { @MainActor in
                            withAnimation {
                                for item in items.compactMap({ dataManager.findTask(withUuidString: $0) }) {
                                    dataManager.move(task: item, to: .open)
                                }
                            }
                        }
                        return true
                    }
                }.frame(minWidth: 600)

            #endif
            #if os(iOS)
                Text(
                    "Choose Next Priorities. Swipe right to move to Priorites \(Image(systemName: TaskItemState.priority.imageName))"
                )
                .font(.title2)
                .foregroundStyle(Color.priority)
                .multilineTextAlignment(.center)
                SimpleListView(
                    color: .open,
                    itemList: dataManager.list(which: .open),
                    headers: TaskItemState.open.subHeaders,
                    showHeaders: true,
                    section: TaskItemState.open.section,
                    id: TaskItemState.open.getListAccessibilityIdentifier
                )
                .frame(minHeight: 300)

            #endif
            Button(action: { presentAlert = true }) {
                Label("Add Task", systemImage: imgAddItem).help("Add new task to list of open tasks.")
            }
        }.frame(minHeight: 300, idealHeight: 800, maxHeight: .infinity)
            .alert(
                "Quick Add", isPresented: $presentAlert,
                actions: {
                    TextField("task title", text: $newTaskName)

                    Button("Cancel", role: .cancel, action: { presentAlert = false })
                    Button(
                        "Add Task",
                        action: {
                            presentAlert = false
                            dataManager.addItem(title: newTaskName)
                        })
                },
                message: {
                    Text("Please enter new task name")
                })
    }
}

//#Preview {
//    // model.stateOfCompassCheck = .review
//    CompassCheckNextPriorities()
//        .environment(dummyPreferences())
//}
