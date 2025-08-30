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
            Image(systemName: preferences.didCompassCheckToday ? imgCompassCheckDone : imgCompassCheckPending)
                .foregroundStyle(preferences.didCompassCheckToday ? Color.green : Color.orange)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 24, height: 24)
            Text(preferences.didCompassCheckToday ? "Done" : "Pending")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(preferences.didCompassCheckToday ? Color.green : Color.orange)
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
                
                Spacer()
                
                Button(action: { compassCheckManager.startCompassCheckNow() }) {
                            Label("Compass Check", systemImage: imgCompassCheckStart)
                                .foregroundStyle(.white)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(TaskItemState.priority.color)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .help("Start compass check")
                        }
                        .buttonStyle(.plain)
                        .frame(height: 24)
            }
        }
    }
}

#Preview {
    StreakView()
        .environment(dummyPreferences())
}
