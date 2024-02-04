//
//  ReviewSoonDueView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 02/02/2024.
//

import SwiftUI

struct ReviewSoonDueView: View {
    @Bindable var model: ReviewModel
    var body: some View {
        VStack{
                Text("These Tasks are soon due. Would you like to turn them into a priority?").font(.title2).foregroundStyle(model.accentColor).multilineTextAlignment(.center)
            HStack {
                ListView(whichList: .priority, model: model.taskModel).frame(minHeight: 300)
                ListView(whichList: .open ,model: model.taskModel)
            }
        }
    }
}

#Preview {
    ReviewSoonDueView(model: dummyReviewModel())
}
