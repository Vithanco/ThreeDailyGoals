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
            ColorPicker("Accent Color", selection: $model.preferences.accentColor)
            DatePicker("Regular Time of Review", selection: $model.preferences.reviewTime, displayedComponents: .hourAndMinute)
            Button("Adjust Review Time") {
                model.setupReviewNotification()
            }
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
        .frame(width: 450, height: 250)
    }
}

#Preview {
    SettingsView(model: TaskManagerViewModel(modelContext: TestStorage()))
}
