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
            ListView(whichList: .priority, model: model)
//                .dropDestination(for: String.self){
//                items, location in
//                for item in items.compactMap({model.findTask(withID: $0)}) {
//                    item.makePriority(position: 0, day: model.today!)
//                }
//                return true
//            }
            Spacer()
            List{
                LinkToList(whichList: .open, model: model)
                LinkToList(whichList: .pendingResponse, model: model)
                LinkToList(whichList: .closed, model: model)
                LinkToList(whichList: .dead, model: model)
            }.frame(maxHeight: 145)
        }
//        .background(Color.background)
            .tdgToolbar(model: model)
    }
}

#Preview {
    LeftSideView(model: dummyViewModel())
}
