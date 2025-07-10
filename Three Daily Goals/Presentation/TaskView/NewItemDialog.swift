//
//  NewItemDialog.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 14/01/2025.
//

import SwiftUI

struct NewItemDialog: View {

    @Bindable var model: TaskManagerViewModel

    func dismiss() {
        model.showNewItemNameDialog = false
    }

    func addTask() {
        model.addAndSelect(title: title.trimmingCharacters(in: .whitespacesAndNewlines))
        dismiss()
    }

    @State var title: String = emptyTaskTitle
    var body: some View {
        VStack {
            Text("Add a new task").bold().foregroundColor(Color.accentColor)
            LabeledContent {
                TextField("titleField", text: $title, axis: .vertical).accessibilityIdentifier("titleField")
                    .bold()
                    .frame(idealHeight: 13)
                    .onSubmit {
                        addTask()
                    }
            } label: {
                Text("Title:").bold().foregroundColor(Color.secondaryColor)
            }.tdgShadow
            Spacer()

            HStack {
                Button(role: .destructive, action: dismiss) {
                    Text("Cancel").foregroundColor(Color.secondaryColor)
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

#Preview {
    NewItemDialog(model: dummyViewModel())
}
