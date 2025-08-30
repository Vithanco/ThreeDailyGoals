//
//  NewItemDialog.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 14/01/2025.
//

import SwiftUI

struct NewItemDialog: View {
    @Environment(UIStateManager.self) private var uiState
    @Environment(DataManager.self) private var dataManager
    @FocusState var isTitleFocused: Bool

    func dismiss() {
        uiState.showNewItemNameDialog = false
    }

    func addTask() {
        dataManager.addAndSelect(title: title.trimmingCharacters(in: .whitespacesAndNewlines))
        title = emptyTaskTitle
        dismiss()
    }

    @State var title: String = emptyTaskTitle

    public init() {
        self.isTitleFocused = true
    }

    var body: some View {
        VStack {
            Text("Add a new task").bold().foregroundColor(TaskItemState.open.color)
            LabeledContent {
                TextField("titleField", text: $title, axis: .vertical).accessibilityIdentifier("titleField")
                    .bold()
                    .frame(idealHeight: 13)
                    .focused($isTitleFocused)
                    .onSubmit {
                        addTask()
                    }
            } label: {
                Text("Title:").bold().foregroundColor(Color.secondary)
            }
            Spacer()

            HStack {
                Button(role: .destructive, action: dismiss) {
                    Text("Cancel").foregroundColor(Color.secondary)
                }
                Spacer()
                Button(action: addTask) {
                    Label("Add Task", systemImage: imgAddItem).help("Add new task to list of open tasks")
                        .accessibilityIdentifier("addTaskWithTitleButton")
                }
            }
        }.padding(5)
            .frame(maxWidth: 300)
    }
}

//#Preview {
//    NewItemDialog()
//        .environment(dummyViewModel())
//}
