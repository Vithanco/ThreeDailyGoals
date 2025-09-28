//
//  NotificationsPreferencesView.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-27.
//

import SwiftUI
import tdgCoreMain

public struct NotificationsPreferencesView: View {
    @Environment(CloudPreferences.self) private var preferences
    @Environment(CompassCheckManager.self) private var compassCheckManager
    
    public var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Header with icon
            HStack {
                Image(systemName: "bell")
                    .foregroundColor(Color.priority)
                    .font(.title2)
                Text("Notification Preferences")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.priority)
            }
            .padding(.bottom, 10)
            
            Text(
                "Configure when and how you receive notifications for your daily Compass Check."
            )
            .multilineTextAlignment(.center)
            .frame(maxWidth: 400, maxHeight: .infinity)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
            
            Spacer().frame(height: 10)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Enable Notifications", isOn: Binding(
                        get: { preferences.notificationsEnabled },
                        set: { preferences.notificationsEnabled = $0 }
                    ))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if preferences.notificationsEnabled {
                        DatePicker(
                            "Time of Compass Check Notification",
                            selection: Binding(
                                get: { preferences.compassCheckTime },
                                set: { preferences.compassCheckTime = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Button("Set Compass Check Time") {
                            compassCheckManager.setupCompassCheckNotification()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Text("Notifications are disabled")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(10)
    }
}

#Preview {
    let appComponents = setupApp(isTesting: true)
    NotificationsPreferencesView()
        .environment(appComponents.preferences)
        .environment(appComponents.compassCheckManager)
}
