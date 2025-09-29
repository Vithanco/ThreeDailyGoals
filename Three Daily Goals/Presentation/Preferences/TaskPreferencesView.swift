//
//  TaskPreferencesView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/02/2024.
//

import SwiftUI
import tdgCoreMain

public struct TaskPreferencesView: View {

    @Environment(CloudPreferences.self) private var preferences

    public var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Header with icon
            HStack {
                Image(systemName: "hand.raised")
                    .foregroundColor(Color.priority)
                    .font(.title2)
                Text("Task Preferences")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.priority)
            }
            .padding(.bottom, 10)
            
            Text(
                "Task management preferences. You can delete tasks from the Graveyard and from the Closed list."
            )
            .multilineTextAlignment(.center)
            .frame(maxWidth: 400, maxHeight: .infinity)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
            
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Task Expiration")
                        .font(.headline)
                    
                    Text("Task expiration settings have been moved to the Compass Check preferences.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    NavigationLink("Configure in Compass Check Steps →") {
                        CompassCheckStepsPreferencesView()
                    }
                    .font(.caption)
                    .foregroundColor(Color.priority)
                }
                .padding(5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(10)
    }
}

#Preview {
    let appComponents = setupApp(isTesting: true)
    TaskPreferencesView()
        .environment(appComponents.preferences)
}
