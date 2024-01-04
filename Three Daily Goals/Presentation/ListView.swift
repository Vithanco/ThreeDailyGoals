//
//  TaskListView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI



struct ListView: View {
    @State var whichList: ListChooser?
    @Bindable var model: TaskManagerViewModel
    
    var list: ListChooser {
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
#if os(macOS)
                    TaskAsLine(item: item).onTapGesture {
                        model.select(which: list, item: item)
                    }
#endif
#if os(iOS)
                    LinkToTask(model: model,item: item)
#endif
                }
            }
        }
            .toolbar {
#if os(iOS)
                ToolbarItem{
                    Button(action: model.undo) {
                        Label("Undo" , systemImage: imgUndo)
                    }.disabled(!model.canUndo)
                }
                ToolbarItem {
                    Button(action: model.redo) {
                        Label("Redo", systemImage: imgRedo)
                    }.disabled(!model.canRedo)
                }
#endif
            }
    }
}



#Preview {
    ListView( model: TaskManagerViewModel(modelContext: sharedModelContainer(inMemory: true).mainContext))
}
