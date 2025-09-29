//
//  ReviewPreferences.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/02/2024.
//

import SwiftUI
import tdgCoreMain

public struct CompassCheckPreferencesView: View {
    @Environment(CloudPreferences.self) private var preferences
    @Environment(TimeProviderWrapper.self) private var timeProviderWrapper
    
    var lastCompassCheck: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: preferences.lastCompassCheck)
    }
    
    
    public var body: some View {
        VStack(spacing: 20) {
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
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Last Compass Check was:")
                        Spacer()
                        Text(lastCompassCheck).foregroundColor(Color.priority)
                    }
                    
                    StreakView()
                    
                    Text("Current Compass Check Interval").bold()
                    HStack {
                        Text("Started:")
                        Spacer()
                        Text(timeProviderWrapper.timeProvider.getCompassCheckInterval().start.timeAgoDisplay())
                    }
                    HStack {
                        Text("Ends:")
                        Spacer()
                        Text(timeProviderWrapper.timeProvider.getCompassCheckInterval().end.timeAgoDisplay())
                    }
                    HStack {
                        Text("Done for this period: ")
                        Spacer()
                        Text(preferences.didCompassCheckToday ? "yes" : "no")
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
    CompassCheckPreferencesView()
        .environment(appComponents.preferences)
}
