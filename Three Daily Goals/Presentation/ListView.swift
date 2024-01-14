//
//  TaskListView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI



struct ListView: View {
    @State var whichList: TaskItemState?
    @Bindable var model: TaskManagerViewModel
    
    var list: TaskItemState {
        return whichList ?? model.whichList
    }
    
    var body: some View {
        List{
            Section (header: VStack(alignment: .leading) {
                ForEach(list.sections) { sec in
                    sec.asText
                }
            }) {
                ForEach(model.list(which: list)) { item in
                    LinkToTask(model: model,item: item, list: list)
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
