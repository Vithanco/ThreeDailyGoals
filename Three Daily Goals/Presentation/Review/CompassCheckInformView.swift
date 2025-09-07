//
//  Inform.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct CompassCheckInformView: View {
    @Environment(CloudPreferences.self) private var preferences
    @Environment(CompassCheckManager.self) private var compassCheckManager

    var body: some View {
        VStack(spacing: 16) {
            // Enhanced streak display
            VStack(spacing: 8) {
                Text("Current Streak")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.priority)
                
                StreakView()
                    .padding(.horizontal, 8)
            }
            
            Spacer(minLength: 10)
            
            Text("It is about time to do a Compass Check and review your tasks")
                .font(.title2)
                .foregroundStyle(Color.priority)
                .frame(maxWidth: 300, maxHeight: .infinity)
                .multilineTextAlignment(.center)
            
            Text(
                "The Compass Check is where the \"daily magic\" happens. By reviewing your tasks daily you can stay on top of your work."
            )
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: 320, maxHeight: 400)
        .padding(16)
    }
}

//#Preview {
//    CompassCheckInformView()
//        .environment(dummyViewModel())
//}
