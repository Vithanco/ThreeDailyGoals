//
//  ReviewPreferences.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/02/2024.
//

import SwiftUI

struct CompassCheckPreferencesView: View {
    @Environment(TaskManagerViewModel.self) private var model
    @Environment(CloudPreferences.self) private var preferences

    var lastCompassCheck: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: preferences.lastCompassCheck)
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
                    Text(lastCompassCheck).foregroundColor(preferences.accentColor)
                }.padding(5)

                StreakView().padding(EdgeInsets(top: 5, leading: 5, bottom: 10, trailing: 5))

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
                    Text(preferences.didCompassCheckToday ? "yes" : "no")
                }
            }
            GroupBox {
                DatePicker(
                    "Time of Compass Check Notification", selection: Binding(
                        get: { preferences.compassCheckTime },
                        set: { preferences.compassCheckTime = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                ).frame(maxWidth: 258).padding(5)
                Button("Set Compass Check Time") {
                    model.compassCheckManager.setupCompassCheckNotification()
                }.buttonStyle(.bordered).padding(5)

                //                Spacer()
                //            }
                Text("or")

                Button("No Notifications Please", role: .destructive) {
                    model.compassCheckManager.deleteNotifications()
                }.buttonStyle(.bordered).padding(5)
            }
            Spacer(minLength: 10)
        }.fixedSize(horizontal: false, vertical: true).padding(10)
    }

}

#Preview {
    CompassCheckPreferencesView()
        .environment(dummyViewModel())
}
