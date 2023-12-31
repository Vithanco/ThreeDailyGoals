//
//  TaskListView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI


struct ListView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var model: ListViewModel
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
                ForEach(model.sections) { sec in
                    sec.asText
                }
            }) {
                ForEach(model.list) { item in
                    #if os(macOS)
                    TaskAsLine(item: item).onTapGesture {
                        taskSelector(model.sections,model.list,item)
                    }
                    #endif
                    #if os(iOS)
                        LinkToTask(item: item)
                    #endif
                }
            }
        }.frame(minHeight: 600)
            .toolbar {
#if os(iOS)
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
#endif
            }
    }
}


struct TaskListViewHelper : View {
    @State var model = ListViewModel(sections: [secGraveyard], list: [TaskItem(), TaskItem()])
    
    var body: some View {
#if os(macOS)
        ListView(model: $model, taskSelector: {a, b, c in debugPrint("triggered")})
#endif
#if os(iOS)
        ListView(model: $model)
#endif
    }
}
#Preview {
    TaskListViewHelper()
}
