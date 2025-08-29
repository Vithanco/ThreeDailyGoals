//
//  StreakView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 08/02/2024.
//

import SwiftUI

struct StreakView: View {
    @Environment(CloudPreferences.self) private var preferences

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: imgStreakActive)
                .foregroundStyle(Color.orange)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 24, height: 24)
            Text("\(preferences.daysOfCompassCheck)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.primary)
        }
    }
}

struct FullStreakView: View {
    @Environment(CompassCheckManager.self) private var compassCheckManager
    @Environment(CloudPreferences.self) private var preferences

    var body: some View {
        GroupBox {
            HStack(spacing: 16) {
                // Streak display
                StreakView()
                
                // Compass check status
                HStack(spacing: 6) {
                    Image(systemName: preferences.didCompassCheckToday ? imgCompassCheckDone : imgCompassCheckPending)
                        .foregroundStyle(preferences.didCompassCheckToday ? Color.green : Color.orange)
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 24, height: 24)
                    Text(preferences.didCompassCheckToday ? "Done" : "Pending")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(preferences.didCompassCheckToday ? Color.green : Color.orange)
                }
                
                Spacer()
                
                // Compass check button
                compassCheckManager.compassCheckButton
            }
        }
    }
}

#Preview {
    StreakView()
        .environment(dummyPreferences())
}
