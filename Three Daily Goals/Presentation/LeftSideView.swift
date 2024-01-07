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
            ListView(whichList: .priorities, model: model).dropDestination(for: String.self){
                items, location in
                for item in items.compactMap({model.findTask(withID: $0)}) {
                    item.makePriority(position: 0, day: model.today!)
                }
                return true
            }
            Spacer()
            List{
                LinkToList(whichList: .openItems, model: model)
                LinkToList(whichList: .closedItems, model: model)
                LinkToList(whichList: .deadItems, model: model)
            }.frame(maxHeight: 160)
        }.background(Color.background)
    }
}

#Preview {
    LeftSideView(model: TaskManagerViewModel(modelContext: sharedModelContainer(inMemory: true).mainContext).addSamples())
}
