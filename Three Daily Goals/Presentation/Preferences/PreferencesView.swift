//
//  PreferencesView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 27/01/2024.
//

import SwiftUI
import tdgCoreMain

public struct PreferencesView: View {
    @State var time: Date = Date.now

    public var body: some View {
        //        VStack{
        TabView {
            CompassCheckPreferencesView()
                .tabItem {
                    Label("Compass Check", systemImage: imgCompassCheck)
                }
            CompassCheckStepsPreferencesView()
                .tabItem {
                    Label("Compass Check Steps", systemImage: "list.bullet.clipboard")
                }
            TagsPreferencesView()
                .tabItem {
                    Label("Tags", systemImage: "tag.circle.fill")
                }
            #if DEBUG
            DebugPreferencesView()
                .tabItem {
                    Label("Debug", systemImage: "wrench.and.screwdriver")
                }
            #endif
        }
        .frame(minHeight: 600)
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
    PreferencesView()
        .environment(appComponents.preferences)
        .environment(appComponents.dataManager)
        .environment(appComponents.uiState)
        .environment(appComponents.compassCheckManager)
}
