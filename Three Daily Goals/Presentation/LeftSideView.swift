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
            model.streakView().frame(maxWidth: .infinity, alignment: .center)
            HStack {
                Spacer()
                Circle().frame(width: 10).foregroundColor(.accentColor).help("Drop Target, as iOS has an issue. Will be hopefully removed with next version of iOS.")
                Spacer()
            }.dropDestination(for: String.self){
                items, location in
                for item in items.compactMap({model.findTask(withID: $0)}) {
                    model.move(task: item, to: .open)
                }
                return true
            }
                
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
        .tdgToolbar(model: model, include: true)
    }
}

#Preview {
    LeftSideView(model: dummyViewModel())
}
