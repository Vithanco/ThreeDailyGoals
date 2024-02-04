//
//  AppearancePreferencesView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/02/2024.
//

import SwiftUI

struct AppearancePreferencesView : View {
    @Bindable var model: TaskManagerViewModel
    var body: some View {
        VStack{
            Spacer()
            Text("Choose which Color you like best for list headers, or use your system's accent color.")
            HStack{
                Spacer()
                ColorPicker("Accent Color", selection: $model.preferences.accentColor)
                Spacer()
            }
            Button("Use System Accent Color"){
                model.resetAccentColor()
            }
            Spacer()
        }.padding(10).frame(maxWidth: 400)
    }
}

#Preview {
    AppearancePreferencesView(model: dummyViewModel())
}
