//
//  ReviewCurrentPriorities.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI
import tdgCoreMain
import tdgCoreWidget

public struct CompassCheckCurrentPriorities: View {
    @Environment(CloudPreferences.self) private var preferences
    @Environment(DataManager.self) private var dataManager
    @Environment(TimeProviderWrapper.self) private var timeProviderWrapper

    @State private var presentAlert = false
    @State private var newTaskName: String = ""

    private func prioritiesTimeText() -> String {
        let hour = timeProviderWrapper.timeProvider.hour(of: timeProviderWrapper.timeProvider.now)

        // If it's before noon (morning), we're reviewing yesterday's priorities
        // If it's noon or later (afternoon/evening), we're reviewing today's priorities
        if hour < 12 {
            return "Yesterday's Priority Tasks"
        } else {
            return "Today's Priority Tasks"
        }
    }

    public var body: some View {
        VStack {
            VStack {
                Text(prioritiesTimeText()).font(.title2).foregroundStyle(Color.priority).padding(5)
                Text("Slide tasks to the left to close them.")
                Text("All non-closed tasks will be moved to open list. You can re-prioritise them later.")
                SimpleListView(
                    color: .priority,
                    itemList: dataManager.list(which: .priority),
                    headers: TaskItemState.priority.subHeaders,
                    showHeaders: false,
                    section: TaskItemState.priority.section,
                    id: TaskItemState.priority.getListAccessibilityIdentifier,
                    enableNavigation: false
                )
            }.frame(minHeight: 300, idealHeight: 500)
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
//    CompassCheckCurrentPriorities()
//        .environment(dummyViewModel())
//}
