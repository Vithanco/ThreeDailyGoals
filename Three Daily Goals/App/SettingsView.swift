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
    
    var body: some View {
        VStack{
            GroupBox(label:
                        Label("Colors", systemImage: "paintbrush")
                    ) {
                Text("Choose which Color you like best, or use your system's accent color.")
                ColorPicker("Accent Color", selection: $model.preferences.accentColor)
                Button("Use System Accent Color"){
                    model.resetAccentColor()
                }
            }
            GroupBox(label:
                        Label("Review", systemImage: imgReview)
            ) {Text("Daily Reviews are at the heart of Three Daily Goals. Choose when you want to plan your Daily Review. Press Button to accept selected time.")
                DatePicker("Regular Time of Review", selection: $model.preferences.reviewTime, displayedComponents: .hourAndMinute)
                Button("Adjust Review Time") {
                    model.setupReviewNotification()
                }
            }
            #if os(iOS)
            Button("Close Preferences"){
                model.showSettingsDialog = false
            }
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
