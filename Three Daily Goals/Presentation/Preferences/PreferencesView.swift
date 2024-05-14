//
//  PreferencesView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 27/01/2024.
//

import SwiftUI





struct PreferencesView: View {
    @Bindable var model: TaskManagerViewModel
    @State var time: Date = Date.now

    var body: some View {
//        VStack{
            TabView {
                ReviewPreferencesView(model: model)
                    .tabItem {
                        Label("Review", systemImage: imgReview)
                    }
                
                AppearancePreferencesView(model: model)
                    .tabItem {
                        Label("Appearance", systemImage: imAppearance)
                    }
                
                TaskPreferencesView(model: model)
                    .tabItem {
                        Label("Tasks", systemImage: "hand.raised")
                    }
                TagsPreferencesView(model: model)
                    .tabItem {
                        Label("Tags", systemImage: "tag.circle.fill")
                    }
            }.frame(minHeight: 250)
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
    PreferencesView(model: dummyViewModel())
}
