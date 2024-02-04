//
//  ReviewPreferences.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/02/2024.
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
            Text("Daily Reviews are at the heart of Three Daily Goals. Choose when you want to plan your Daily Review. In the morning? Or the evening before?").multilineTextAlignment(.center)
            Spacer().frame(height: 10)
            Text("Last Review was:")
            Text(lastReview).foregroundColor(model.accentColor)
//            HStack{
//                Spacer()
                DatePicker("Regular Time of Review", selection: $model.preferences.reviewTime, displayedComponents: .hourAndMinute).frame(maxWidth: 258)
//                Spacer()
//            }
            
            Button("Set Review Time") {
                model.setupReviewNotification()
            }.buttonStyle(.bordered)
            Spacer()
        }.padding(10).frame(maxWidth: 400)
    }
    
}

#Preview {
    ReviewPreferencesView(model: dummyViewModel())
}
