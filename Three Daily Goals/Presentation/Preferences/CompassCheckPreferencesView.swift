//
//  ReviewPreferences.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/02/2024.
//

import SwiftUI

struct CompassCheckPreferencesView: View {
    @Bindable var model: TaskManagerViewModel

    var lastCompassCheck: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: model.preferences.lastCompassCheck)
    }

    var body: some View {
        VStack {
            Spacer()
            Text(
                "Daily Compass Checks are at the heart of Three Daily Goals. Choose when you want to plan your Daily Compass Check. In the morning? Or the evening before?"
            )
            .multilineTextAlignment(.center)
            .frame(maxWidth: 400, maxHeight: .infinity)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
            Text(
                "Three Daily Goals is assuming that you should do a Compass Check to occur at least once between noon of one day and noon the next day."
            ).multilineTextAlignment(.center)
            Spacer().frame(height: 10)
            GroupBox {
                HStack {
                    Text("Last Compass Check was:")
                    Text(lastCompassCheck).foregroundColor(model.accentColor)
                }.padding(5)

                StreakView(model: model).padding(EdgeInsets(top: 5, leading: 5, bottom: 10, trailing: 5))

                Text("Current Compass Check Interval").bold()
                HStack {
                    Text("Started:")
                    Text(getCompassCheckInterval().start.timeAgoDisplay())
                }
                HStack {
                    Text("Ends:")
                    Text(getCompassCheckInterval().end.timeAgoDisplay())
                }
                HStack {
                    Text("Done for this period: ")
                    Text(model.preferences.didCompassCheckToday ? "yes" : "no")
                }
            }
            GroupBox {
                DatePicker(
                    "Time of Compass Check Notification", selection: $model.preferences.compassCheckTime,
                    displayedComponents: .hourAndMinute
                ).frame(maxWidth: 258).padding(5)
                Button("Set Compass Check Time") {
                    model.setupCompassCheckNotification()
                }.buttonStyle(.bordered).padding(5)

                //                Spacer()
                //            }
                Text("or")

                Button("No Notifications Please", role: .destructive) {
                    model.deleteNotifications()
                }.buttonStyle(.bordered).padding(5)
            }
            Spacer(minLength: 10)
        }.fixedSize(horizontal: false, vertical: true).padding(10)
    }

}

#Preview {
    CompassCheckPreferencesView(model: dummyViewModel())
}
