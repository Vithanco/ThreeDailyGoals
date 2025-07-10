//
//  TaskPreferencesView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/02/2024.
//

import SwiftUI

struct TaskPreferencesView: View {
    @Bindable var model: TaskManagerViewModel

    var body: some View {
        VStack {
            Spacer()
            Text(
                "Sort old Tasks out. They seem to be not important to you. You can always find them again in the graveyard. Btw, you can delete tasks from the Graveyard and from the Closed list."
            )
            HStack {
                Spacer()
                Spacer()
                Text("Expire after")
                Stepper(
                    value: $model.preferences.expiryAfter, in: 30...1040, step: 10,
                    label: {
                        Text("  " + model.preferences.expiryAfterString).foregroundColor(model.accentColor)
                    })
                Text(" days.")
                Spacer()
                Spacer()
            }
            Spacer()
        }.padding(10).frame(maxWidth: 400)
    }
}

#Preview {
    TaskPreferencesView(model: dummyViewModel())
}
