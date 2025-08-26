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
        Text("\(Image(systemName: imgStreak)) \(preferences.streakText)").foregroundStyle(Color.red)
    }
}

struct FullStreakView: View {
    @Environment(CompassCheckManager.self) private var compassCheckManager
    
    var body: some View {
        GroupBox {
            HStack {
                StreakView()
                compassCheckManager.compassCheckButton
            }
        }
    }
}

#Preview {
    StreakView()
        .environment(dummyViewModel())
        .environment(dummyPreferences())
}
