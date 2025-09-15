//
//  ReviewPreferences.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/02/2024.
//

import SwiftUI

struct CompassCheckPreferencesView: View {
    @Environment(CloudPreferences.self) private var preferences
    @Environment(CompassCheckManager.self) private var compassCheckManager
    @Environment(TimeProviderWrapper.self) private var timeProviderWrapper

    var lastCompassCheck: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: preferences.lastCompassCheck)
    }
    

    var body: some View {
        VStack {
            Spacer()
            
            // Header with icon
            HStack {
                Image(systemName: imgCompassCheck)
                    .foregroundColor(Color.priority)
                    .font(.title2)
                Text("Compass Check Preferences")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.priority)
            }
            .padding(.bottom, 10)
            
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
                    Text(lastCompassCheck).foregroundColor(Color.priority)
                }.padding(5)

                StreakView().padding(EdgeInsets(top: 5, leading: 5, bottom: 10, trailing: 5))

                Text("Current Compass Check Interval").bold()
                HStack {
                    Text("Started:")
                    Text(timeProviderWrapper.timeProvider.getCompassCheckInterval().start.timeAgoDisplay())
                }
                HStack {
                    Text("Ends:")
                    Text(timeProviderWrapper.timeProvider.getCompassCheckInterval().end.timeAgoDisplay())
                }
                HStack {
                    Text("Done for this period: ")
                    Text(preferences.didCompassCheckToday ? "yes" : "no")
                }
            }.frame(width: 390)
            GroupBox {
                DatePicker(
                    "Time of Compass Check Notification",
                    selection: Binding(
                        get: { preferences.compassCheckTime },
                        set: { preferences.compassCheckTime = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                ).padding(5)
                Button("Set Compass Check Time") {
                    compassCheckManager.setupCompassCheckNotification()
                }.buttonStyle(.bordered).padding(5)
                
                //                Spacer()
                //            }
                Text("or")
                
                Button("No Notifications Please", role: .destructive) {
                    compassCheckManager.deleteNotifications()
                }.buttonStyle(.bordered).padding(5)
            }.frame(width: 390)
            
            GroupBox {
                Text("Compass Check Steps").bold().padding(.bottom, 5)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(compassCheckManager.steps, id: \.id) { step in
                        let isComingSoon = step.id == "plan"
                        
                        if isComingSoon {
                            HStack {
                                Toggle(step.name, isOn: Binding(
                                    get: { preferences.isCompassCheckStepEnabled(stepId: step.id) },
                                    set: { preferences.setCompassCheckStepEnabled(stepId: step.id, enabled: $0) }
                                ))
                                Text("(Coming Soon)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Toggle(step.name, isOn: Binding(
                                get: { preferences.isCompassCheckStepEnabled(stepId: step.id) },
                                set: { preferences.setCompassCheckStepEnabled(stepId: step.id, enabled: $0) }
                            ))
                        }
                    }
                }
                .padding(5)
            }.frame(width: 390)
            
            Spacer(minLength: 10)
        }
        .frame(maxWidth: 400)
        .fixedSize(horizontal: false, vertical: true)
        .padding(10)
    }

}

#Preview {
    let appComponents = setupApp(isTesting: true)
    return CompassCheckPreferencesView()
        .environment(appComponents.preferences)
        .environment(appComponents.compassCheckManager)
}
