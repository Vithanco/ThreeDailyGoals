//
//  TaskListView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI


extension ListHeader {
    var asText: Text {
        Text("Last updated: " + self.name).font(.callout)
    }
}


struct ListView: View {
    @State var whichList: TaskItemState?
    @Bindable var model: TaskManagerViewModel
    
    var list: TaskItemState {
        return whichList ?? model.whichList
    }
    
    var body: some View {
            let itemList = model.list(which: list)
            let headers = list.subHeaders
//        let partialLists : [[TaskItem]] = headers.map({$0.filter(items: itemList)})
        
            
        SimpleListView(itemList: itemList, headers: headers, showHeaders: list != .priority, section: list.section, id: list.getListAccessibilityIdentifier, model: model)
            .frame(minHeight: 145, maxHeight: .infinity)
            .background(Color.background)
            .tdgToolbar(model: model, include : !isLargeDevice)

        .dropDestination(for: String.self){
            items, location in
            for item in items.compactMap({model.findTask(withID: $0)}) {
                model.move(task: item, to: list)
            }
            return true
        }
    }
}

#Preview {
    ListView( model: dummyViewModel())
}
