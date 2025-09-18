//
//  TaskPreferencesView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/02/2024.
//

import SwiftUI
import tdgCoreMain

public struct TaskPreferencesView: View {

    @Environment(CloudPreferences.self) private var preferences

    public var body: some View {
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
                    value: Binding(
                        get: { preferences.expiryAfter },
                        set: { preferences.expiryAfter = $0 }
                    ), in: 30...1040, step: 10,
                    label: {
                        Text("  " + preferences.expiryAfterString).foregroundColor(Color.priority)
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
    let appComponents = setupApp(isTesting: true)
    TaskPreferencesView()
        .environment(appComponents.preferences)
}
