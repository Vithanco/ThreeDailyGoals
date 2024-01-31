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
    
    let headers = defaultListHeaders;
    
    var body: some View {
        let itemList = model.list(which: list)
        List{
            Section (header: VStack(alignment: .leading) {
                ForEach(list.sections) { sec in
                    sec.asText.foregroundStyle(model.accentColor)
                }
            }) {
                ForEach(headers) {header in
                    let partialList = itemList.filter(header.filter)
                    if partialList.count > 0 {
                        if list != .priority {
                        header.asText
                            .foregroundStyle(model.accentColor)
                            .listRowSeparator(.hidden)
                        }
                        ForEach(partialList) { item in
                            LinkToTask(model: model,item: item, list: list).listRowSeparator(.visible)
                        }
                    }
                }
            }
        }.frame(minHeight: 200).background(Color.background)
            .dropDestination(for: String.self){
                items, location in
                for item in items.compactMap({model.findTask(withID: $0)}) {
                    model.move(task: item, to: list)
                }
                return true
            }
#if os(iOS)
            .tdgToolbar(model: model)
#endif
    }
}

#Preview {
    ListView( model: TaskManagerViewModel(modelContext: TestStorage()))
}
