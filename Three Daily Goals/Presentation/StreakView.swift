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
            Text("\(preferences.daysOfCompassCheck)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black)
            Image(systemName: imgStreakActive)
                .foregroundStyle(Color.priority)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 24, height: 24)
            Text("Today:")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.black)
            Image(systemName: preferences.didCompassCheckToday ? imgCompassCheckDone : imgCompassCheckPending)
                .foregroundStyle(preferences.didCompassCheckToday ? Color.closed : Color.open)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 24, height: 24)
        }
    }
}

struct FullStreakView: View {
    @Environment(CompassCheckManager.self) private var compassCheckManager
    @Environment(CloudPreferences.self) private var preferences
    @Environment(\.colorScheme) private var colorScheme

    // Adaptive background color for streak view
    private var streakBackground: Color {
        colorScheme == .dark ? Color.neutral800 : Color.neutral50
    }
    
    // Adaptive border color for streak view
    private var streakBorder: Color {
        colorScheme == .dark ? Color.neutral700 : Color.neutral200
    }
    

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
                                .background(Color.priority)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .help("Start compass check")
                        }
                        .buttonStyle(.plain)
                        .frame(height: 20)
            }
        }
        .background(streakBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(streakBorder, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 1)
    }
}

#Preview {
    StreakView()
        .environment(dummyPreferences())
}
