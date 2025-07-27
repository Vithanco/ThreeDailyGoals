//
//  ReviewCurrentPriorities.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct CompassCheckCurrentPriorities: View {
    @Bindable var model: TaskManagerViewModel

    @State private var presentAlert = false
    @State private var newTaskName: String = ""

    var body: some View {
        VStack {
            #if os(macOS)
                Text(
                    "Choose Next Priorities via drag'n'drop \(Image(systemName: "arrowshape.left.arrowshape.right.fill"))"
                ).font(.title2).foregroundStyle(model.accentColor).multilineTextAlignment(.center)
                HStack {
                    ListView(whichList: .priority, model: model).frame(minHeight: 300)
                    ListView(whichList: .open, model: model)
                }
            #endif
            #if os(iOS)
                VStack {
                    Text("Current Priority Tasks").font(.title2).foregroundStyle(model.accentColor).padding(5)
                    Text("Slide tasks to the left to close them.")
                    Text("All non-closed tasks will be moved to open list. You can re-prioritise them later.")
                    ListView(whichList: .priority, model: model)
                }.frame(minHeight: 300, idealHeight: 500)
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
                            model.addItem(title: newTaskName)
                        })
                },
                message: {
                    Text("Please enter new task name")
                })
    }
}

#Preview {
    let model = dummyViewModel()
    model.stateOfCompassCheck = .currentPriorities
    return CompassCheckCurrentPriorities(model: model)
}
