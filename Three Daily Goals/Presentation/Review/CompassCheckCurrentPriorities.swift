//
//  ReviewCurrentPriorities.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct CompassCheckCurrentPriorities: View {
    @Environment(TaskManagerViewModel.self) private var model
    @Environment(CloudPreferences.self) private var preferences

    @State private var presentAlert = false
    @State private var newTaskName: String = ""

    var body: some View {
        VStack {
            VStack {
                Text("Current Priority Tasks").font(.title2).foregroundStyle(preferences.accentColor).padding(5)
                Text("Slide tasks to the left to close them.")
                Text("All non-closed tasks will be moved to open list. You can re-prioritise them later.")
                ListView(whichList: .priority)
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
                            model.dataManager.addItem(title: newTaskName)
                        })
                },
                message: {
                    Text("Please enter new task name")
                })
    }
}

#Preview {
    CompassCheckCurrentPriorities()
        .environment(dummyViewModel())
}
