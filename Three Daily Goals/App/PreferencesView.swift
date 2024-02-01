//
//  PreferencesView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 27/01/2024.
//

import SwiftUI

struct ReviewPreferencesView : View {
    @Bindable var model: TaskManagerViewModel
    
    var lastReview: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: model.preferences.lastReview) // "January 14, 2021"
        
    }
        
    var body: some View {
        VStack{
            Spacer()
            Text("Daily Reviews are at the heart of Three Daily Goals. Choose when you want to plan your Daily Review. Press Button to accept selected time.")
            Spacer().frame(height: 10)
            Text("Last Review was:")
            Text(lastReview).foregroundColor(model.accentColor)
            DatePicker("Regular Time of Review", selection: $model.preferences.reviewTime, displayedComponents: .hourAndMinute)
            Button("Adjust Review Time") {
                model.setupReviewNotification()
            }.buttonStyle(.bordered)
            Spacer()
        }
    }
    
}

struct AppearancePreferencesView : View {
    @Bindable var model: TaskManagerViewModel
    var body: some View {
        VStack{
            Spacer()
            Text("Choose which Color you like best, or use your system's accent color.")
            ColorPicker("Accent Color", selection: $model.preferences.accentColor)
            Button("Use System Accent Color"){
                model.resetAccentColor()
            }
            Spacer()
        }
    }
    
}

struct TaskPreferencesView : View {
    @Bindable var model: TaskManagerViewModel
    var body: some View {
        VStack{
            Spacer()
            Text("Sort old Tasks out. They seem to be not important to you. You can always find them again in the graveyard.")
            HStack {
                Spacer()
                Spacer()
                Text("Expire after")
                
                //                    Text(model.preferences.expiryAfterString).multilineTextAlignment(.trailing).foregroundColor(model.accentColor)
                Stepper(value: $model.preferences.expiryAfter, in: 10...1000, step: 10, label: {Text("  " + model.preferences.expiryAfterString).foregroundColor(model.accentColor)})
                Text(" days.")
                Spacer()
                Spacer()
            }
            Spacer()
        }
    }
}

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
    PreferencesView(model: TaskManagerViewModel(modelContext: TestStorage()))
}
