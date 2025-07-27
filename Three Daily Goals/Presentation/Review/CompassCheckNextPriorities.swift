//
//  ReviewNextPriorities.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct CompassCheckNextPriorities: View {

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
                Text(
                    "Choose Next Priorities. Swipe left to move to Priorites \(Image(systemName: TaskItemState.priority.imageName))"
                )
                .font(.title2)
                .foregroundStyle(model.accentColor)
                .multilineTextAlignment(.center)
                ListView(whichList: .open, model: model)
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
    model.stateOfCompassCheck = .review
    return CompassCheckNextPriorities(model: model)
}
