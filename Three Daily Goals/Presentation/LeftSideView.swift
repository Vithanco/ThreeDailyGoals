//
//  LeftSideView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 07/01/2024.
//

import SwiftUI

struct LeftSideView: View {
    @Bindable var model : TaskManagerViewModel
    var body: some View {
        VStack(alignment: .leading){
#if os(iOS)
            Text("\(Image(systemName: imgStreak)) Streak: \(model.preferences.daysOfReview) days").foregroundStyle(Color.red).frame(maxWidth: .infinity, alignment: .center)
#endif
            ListView(whichList: .priority, model: model)
            Spacer()

            List{
                LinkToList(whichList: .open, model: model)
                LinkToList(whichList: .pendingResponse, model: model)
                LinkToList(whichList: .closed, model: model)
                LinkToList(whichList: .dead, model: model)
            }.frame(maxHeight: 145)
        }
        .tdgToolbar(model: model)
    }
}

#Preview {
    LeftSideView(model: dummyViewModel())
}
