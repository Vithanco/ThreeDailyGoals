//
//  TaskListView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI

struct ListView: View {
    @Environment(\.modelContext) private var modelContext
    var section: [TaskSection]
    var items: [TaskItem]
#if os(macOS)
    var taskSelector: TaskSelector
#endif
    
    @State private var canUndo = false
    @State private var canRedo = false
    
    private func undo() {
        modelContext.undoManager?.undo()
        updateUndoRedoStatus()
    }
    
    private func redo() {
        modelContext.undoManager?.redo()
        updateUndoRedoStatus()
    }
    
    private func updateUndoRedoStatus() {
        canUndo =  modelContext.undoManager?.canUndo ?? false
        canRedo =  modelContext.undoManager?.canRedo ?? false
    }
    
    var body: some View {
        List {
            Section (header:
                        VStack(alignment: .leading) {
                ForEach(section) { sec in
                    sec.asText
                }
            }) {
                ForEach(items) { item in
                    #if os(macOS)
                    Text(item.title).onTapGesture {
                        taskSelector(section,items,item)
                    }
                    #endif
                    #if os(iOS)
                        LinkToTask(item: item)
                    #endif
                }
            }
        }.toolbar {
            
            ToolbarItem{
                Button(action: undo) {
                    Label("Undo", systemImage: imgUndo)
                }.disabled(!canUndo)
            }
            ToolbarItem {
                Button(action: redo) {
                    Label("Redo", systemImage: imgRedo)
                }.disabled(!canRedo)
            }
        } 
    }
}

#if os(macOS)
struct TaskListViewHelper : View {
    @State var section: [TaskSection]
    @State var items: [TaskItem]
    let taskSelector : TaskSelector
    
    var body: some View {
        
        ListView(section: section, items: items, taskSelector: {a, b, c in debugPrint("triggered")})
    }
}
#Preview {
    TaskListViewHelper(section: [secGraveyard], items: [TaskItem(), TaskItem()],taskSelector: {a,b,c in debugPrint("triggered")})
}
#endif

#if os(iOS)
struct TaskListViewHelper : View {
    @State var section: [TaskSection]
    @State var items: [TaskItem]
    
    var body: some View {
        ListView(section: section, items: items)
    }
}
#Preview {
    TaskListViewHelper(section: [secGraveyard], items: [TaskItem(), TaskItem()])
}
#endif
