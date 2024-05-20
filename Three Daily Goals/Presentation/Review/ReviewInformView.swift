//
//  Inform.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct ReviewInformView: View {
    
    @Bindable var model: TaskManagerViewModel
    
    var body: some View {
        VStack{
            Text("It is about time to review your tasks").font(.title2).foregroundStyle(model.accentColor).padding(10)
            Text("This review is where the daily magic happens. You can choose the best daily time in the preferences.").padding(10)
            Text("This dialog will only be shown when your last review is more than 4 hours ago. ")
                .frame(maxWidth: 500)
                .padding(10)
            
            HStack{
                Spacer()
                Button(action: model.waitABit) {
                    Text("I would rather start in 5 min")
                }.buttonStyle(.bordered)
                Spacer()
            }
        }.frame(minHeight: 300, idealHeight: 300)
    }
}

#Preview {
    let model = dummyViewModel()
    model.stateOfReview = .inform
    return ReviewInformView(model: model)
}
