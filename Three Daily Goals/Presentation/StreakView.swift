//
//  StreakView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 08/02/2024.
//

import SwiftUI

struct StreakView: View {
    @Environment(CloudPreferences.self) private var preferences
    @Bindable var model: TaskManagerViewModel
    
    var body: some View {
        Text("\(Image(systemName: imgStreak)) \(preferences.streakText)").foregroundStyle(Color.red)
    }
}

struct FullStreakView: View {
    @Environment(CloudPreferences.self) private var preferences
    @Bindable var model: TaskManagerViewModel
    
    var body: some View {
        GroupBox {
            HStack {
                StreakView(model: model)
                model.compassCheckButton
            }
        }
    }
}

#Preview {
    StreakView(model: dummyViewModel())
        .environment(dummyPreferences())
}
