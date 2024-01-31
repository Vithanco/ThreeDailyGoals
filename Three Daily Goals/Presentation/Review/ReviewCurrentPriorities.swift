//
//  ReviewCurrentPriorities.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct ReviewCurrentPriorities: View {
    @Bindable var model: ReviewModel
    
    var body: some View {
        VStack{
            Text("Current Priority Tasks").font(.title2).foregroundStyle(model.accentColor)
            
            Text("Click on Checkbox to close them")
            ListView(whichList: .priority, model: model.taskModel)
            HStack{
                Button(action: model.closeAllPriorities ){
                    Text("Close All")
                }
                Button(action: model.movePrioritiesToOpen){
                    Text("Move All to Open")
                }
            }
        }.frame(minHeight: 800)
        
    }
}

#Preview {
    ReviewCurrentPriorities(model: dummyReviewModel())
}
