//
//  ReviewNextPriorities.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct CompassCheckNextPriorities: View {
    @Environment(CloudPreferences.self) private var preferences
    @Environment(DataManager.self) private var dataManager

    @State private var presentAlert = false
    @State private var newTaskName: String = ""

    var body: some View {
        VStack {
            #if os(macOS)

                Text(
                    "Choose Next Priorities via drag'n'drop \(Image(systemName: "arrowshape.left.arrowshape.right.fill"))"
                ).font(.title2).foregroundStyle(Color.priority).multilineTextAlignment(.center)
                HStack {
                    ListView(whichList: .priority).frame(minHeight: 300)
                    ListView(whichList: .open)
                }

            #endif
            #if os(iOS)
                Text(
                    "Choose Next Priorities. Swipe left to move to Priorites \(Image(systemName: TaskItemState.priority.imageName))"
                )
                .font(.title2)
                .foregroundStyle(preferences.accentColor)
                .multilineTextAlignment(.center)
                ListView(whichList: .open)
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
