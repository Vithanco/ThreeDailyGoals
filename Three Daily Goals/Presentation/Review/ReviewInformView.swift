//
//  Inform.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct ReviewInformView: View {
    
    @Bindable var model: ReviewModel
    
    var body: some View {
        VStack{
            Text("It is about time to review your tasks").font(.title2).foregroundStyle(model.accentColor)
            Text("This review is where the daily magic happens. You can choose the best daily time in the preferences. This dialog will only be shown when your last review is more than 4 hours ago. ")
                .frame(maxWidth: 500)
                .padding(10)
            
            HStack{
                Spacer()
                Button(action: model.waitABit) {
                    Text("Start in 5 min")
                }.buttonStyle(.bordered)
                Spacer()
            }
        }.frame(minHeight: 300, idealHeight: 300)
    }
}

#Preview {
    ReviewInformView(model: dummyReviewModel())
}
