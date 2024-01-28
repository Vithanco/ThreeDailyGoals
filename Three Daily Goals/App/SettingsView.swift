//
//  SettingsView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 27/01/2024.
//

import SwiftUI

struct ReviewSettingsView : View {

    var body: some View {
        Text("Review Settings")
    }
    
}

struct AppearanceSettingsView : View {

    var body: some View {
        Text("Appearance Settings")
    }
    
}

struct TaskSettingsView : View {

    var body: some View {
        Text("Appearance Settings")
    }
    
}

struct SettingsView: View {
    var settings: Preferences 
    var body: some View {
        TabView {
            ReviewSettingsView()
                    .tabItem {
                        Label("Review", systemImage: imgMagnifyingGlass)
                    }
                
                AppearanceSettingsView()
                    .tabItem {
                        Label("Appearance", systemImage: imAppearance)
                    }
                
                TaskSettingsView()
                    .tabItem {
                        Label("Tasks", systemImage: "hand.raised")
                    }
        }
        .frame(width: 450, height: 250)
    }
}

#Preview {
    SettingsView(settings: Preferences())
}
