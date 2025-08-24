//
//  Inform.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct CompassCheckInformView: View {

    @Environment(TaskManagerViewModel.self) private var model
    @Environment(CloudPreferences.self) private var preferences

    var body: some View {
        VStack(spacing: 5) {
            GroupBox(label: Text("Current Streak").foregroundStyle(preferences.accentColor)) {
                StreakView().padding(5).border(Color.gray)
            }
            Spacer(minLength: 10)
            Text("It is about time to do a Compass Check and review your tasks").font(.title2)
                .foregroundStyle(preferences.accentColor)
                .frame(maxWidth: 300, maxHeight: .infinity)
            Text(
                "The Compass Check is where the \"daily magic\" happens. By reviewing your tasks daily you can stay on top of your work."
            )
            .multilineTextAlignment(.leading)
            Button(action: model.waitABit) {
                Text("Remind me in 5 min")
            }.buttonStyle(.bordered)
        }.frame(maxWidth: 320, maxHeight: 400)
    }
}

#Preview {
    CompassCheckInformView()
        .environment(dummyViewModel())
}
