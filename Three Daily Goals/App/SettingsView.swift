//
//  SettingsView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 27/01/2024.
//

import SwiftUI

//struct ReviewSettingsView : View {
//    @Bindable var settings: Preferences
//    var body: some View {
//        Text("Review Settings")
//    }
//    
//}
//
//struct AppearanceSettingsView : View {
//    @Bindable var settings: Preferences
//    var body: some View {
//        
//    }
//    
//}
//
//struct TaskSettingsView : View {
//    @Bindable var settings: Preferences
//    var body: some View {
//        
//            Text("Task-related Settings")
//    }
//    
//}

struct SettingsView: View {
    @Bindable var model: TaskManagerViewModel
    @State var time: Date = Date.now
    
    var lastReview: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: model.preferences.lastReview) // "January 14, 2021"
        
    }
    
    var body: some View {
        VStack{
            GroupBox(label:
                        Label("Colors", systemImage: "paintbrush").foregroundColor(model.accentColor)
                    ) {
                Text("Choose which Color you like best, or use your system's accent color.")
                ColorPicker("Accent Color", selection: $model.preferences.accentColor)
                Button("Use System Accent Color"){
                    model.resetAccentColor()
                }
            }
            GroupBox(label:
                        Label("Review", systemImage: imgReview).foregroundColor(model.accentColor)
            ) {
                Text("Daily Reviews are at the heart of Three Daily Goals. Choose when you want to plan your Daily Review. Press Button to accept selected time.")
                Spacer().frame(height: 10)
                    Text("Last Review was:")
                    Text(lastReview).foregroundColor(model.accentColor)
                DatePicker("Regular Time of Review", selection: $model.preferences.reviewTime, displayedComponents: .hourAndMinute)
                Button("Adjust Review Time") {
                    model.setupReviewNotification()
                }.buttonStyle(.bordered)
            }
            
            GroupBox(label:
                        Label("Graveyard", systemImage: imgGraveyard).foregroundColor(model.accentColor)
                    ) {
                Text("Sort old Tasks out. They seem to be not important to you. You can always find them again in the graveyard.")
                HStack {
                    Text("Expire after ")
                    
                    Text(model.preferences.expiryAfterString).foregroundColor(model.accentColor)
                    Stepper("", value: $model.preferences.expiryAfter, in: 10...1000, step: 10 )
                    Text(" days .")
                    Spacer()
                }
                Button("Use System Accent Color"){
                    model.resetAccentColor()
                }
            }
            #if os(iOS)
            Spacer()
            Button("Close Preferences"){
                model.showSettingsDialog = false
            }.buttonStyle(.borderedProminent)
            #endif
        }
        
//        TabView {
//            ReviewSettingsView(settings: settings)
//                    .tabItem {
//                        Label("Review", systemImage: imgMagnifyingGlass)
//                    }
//                
//            AppearanceSettingsView(settings: settings)
//                    .tabItem {
//                        Label("Appearance", systemImage: imAppearance)
//                    }
//                
//                TaskSettingsView(settings: settings)
//                    .tabItem {
//                        Label("Tasks", systemImage: "hand.raised")
//                    }
//        }
    
    }
}

#Preview {
    SettingsView(model: TaskManagerViewModel(modelContext: TestStorage()))
}
