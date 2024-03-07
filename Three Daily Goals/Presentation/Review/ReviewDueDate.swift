//
//  ReviewPendingResponses.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct ReviewDueDate: View {
    @Bindable var model: ReviewModel
    
    var body: some View {
        VStack{
            Text("These Tasks are close to their due Dates. They were now  moved to Priority").font(.title2).foregroundStyle(model.accentColor)
            Spacer()
            Text("Swipe left in order to close them, or move them back to Open Tasks (you can prioritise them in the next step).")
            ListView(whichList: .pendingResponse, model: model.taskModel)
        }.frame(minHeight: 300, idealHeight: 800, maxHeight:.infinity )
    }
}

#Preview {
    ReviewPendingResponses(model: dummyReviewModel())
}
