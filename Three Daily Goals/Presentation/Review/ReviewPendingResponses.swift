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
            Text("Can you close some tasks you wait on?").font(.title2).foregroundStyle(model.accentColor)
            Text("Click on Checkbox (left) to close them, or move them back to Open Tasks (you can prioritise them in the next step) - on the right")
        ListView(whichList: .pendingResponse, model: model.taskModel)
        Button(action: model.moveStateForward) {
            Text("Next Step")
        }.buttonStyle(.bordered)
    }
}

#Preview {
    ReviewPendingResponses(model: dummyReviewModel())
}
