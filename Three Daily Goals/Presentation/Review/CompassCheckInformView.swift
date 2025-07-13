//
//  Inform.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct CompassCheckInformView: View {

    @Bindable var model: TaskManagerViewModel

    var body: some View {
        VStack(spacing:5) {
            GroupBox(label:  Text("Current Streak").foregroundStyle(model.accentColor) ) {
                model.streakView().padding(5).border(Color.gray)
            }
            Spacer (minLength: 10)
            Text("It is about time to do a Compass Check and review your tasks").font(.title2)
                .foregroundStyle(model.accentColor)
                .frame(maxWidth: 300, maxHeight: .infinity)
            Text("The Compass Check is where the \"daily magic\" happens. By reviewing your tasks daily you can stay on top of your work.\n\n" +
                 "You can choose the best daily time in the preferences.\n\n" +
                 "This dialog will only be shown when your last Compass Check is more than 4 hours ago. ")
                .frame(maxWidth: 300, maxHeight: .infinity)
            Button(action: model.waitABit) {
                Text("Remind me in 5 min")
            }.buttonStyle(.bordered)
        }.frame(maxWidth: 320,maxHeight: 400)
    }
}

#Preview {
    let model = dummyViewModel()
    model.stateOfCompassCheck = .inform
    return CompassCheckInformView(model: model)
}
