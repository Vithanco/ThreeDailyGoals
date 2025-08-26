//
//  PreferencesView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 27/01/2024.
//

import SwiftUI

struct PreferencesView: View {
    @State var time: Date = Date.now

    var body: some View {
        //        VStack{
        TabView {
            CompassCheckPreferencesView()
                .tabItem {
                    Label("Compass Check", systemImage: imgCompassCheck)
                }

            AppearancePreferencesView()
                .tabItem {
                    Label("Appearance", systemImage: imAppearance)
                }

            TaskPreferencesView()
                .tabItem {
                    Label("Tasks", systemImage: "hand.raised")
                }
            TagsPreferencesView()
                .tabItem {
                    Label("Tags", systemImage: "tag.circle.fill")
                }
        }
        //#if os(iOS)
        //            Spacer()
        //            Button("Close Preferences"){
        //                model.showSettingsDialog = false
        //            }.buttonStyle(.borderedProminent)
        //#endif
        //        }
    }
}

#Preview {
    let appComponents = setupApp(isTesting: true)
    return PreferencesView()
        .environment(appComponents.preferences)
        .environment(appComponents.dataManager)
        .environment(appComponents.uiState)
        .environment(appComponents.compassCheckManager)
}
