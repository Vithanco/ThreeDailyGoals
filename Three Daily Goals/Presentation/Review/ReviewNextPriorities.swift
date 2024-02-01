//
//  ReviewNextPriorities.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct ReviewNextPriorities: View {
    
    @Bindable var model: ReviewModel
    var body: some View {
        VStack{
                Text("Choose Next Priorities via drag'n'drop \(Image(systemName: "arrowshape.left.arrowshape.right.fill"))").font(.title2).foregroundStyle(model.accentColor).multilineTextAlignment(.center)
            HStack {
                ListView(whichList: .priority, model: model.taskModel).frame(minHeight: 300)
                ListView(whichList: .open ,model: model.taskModel)
            }
        }
    }
}

#Preview {
    ReviewNextPriorities(model: dummyReviewModel())
}
