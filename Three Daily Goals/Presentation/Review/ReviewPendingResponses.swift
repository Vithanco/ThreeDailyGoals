//
//  ReviewPendingResponses.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct ReviewPendingResponses: View {
    @Bindable var model: ReviewModel
    
    var body: some View {
        VStack{
            Text("Can you close some tasks you wait on?").font(.title2).foregroundStyle(model.accentColor)
            Spacer()
            Text("Swipe left in order to close them, or move them back to Open Tasks (you can prioritise them in the next step).")
            ListView(whichList: .pendingResponse, model: model.taskModel)
        }
    }
}

#Preview {
    ReviewPendingResponses(model: dummyReviewModel())
}
