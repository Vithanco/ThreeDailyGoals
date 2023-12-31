//
//  ContentView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    
    @Environment(\.modelContext) private var modelContext
   
    
#if os(macOS)
    @State private var listModel = ListViewModel(sections: [], list: [])
    func select(sections: [TaskSection], list: [TaskItem], item: TaskItem?) {
        withAnimation{
            listModel.sections = sections
            listModel.list = list
            selectedItem = item
        }
    }
#endif
    
    var body: some View {
        let _ = updateModels()
        NavigationSplitView {
            VStack(alignment: .leading){
                if let today = today {
#if os(macOS)
                    Priorities(priorities: today,taskSelector: select)
                    List {
                        DatedTaskList(listModel: $openModel, taskSelector: select)
                        DatedTaskList(listModel: $deadModel, taskSelector: select)
                        DatedTaskList(listModel: $closedModel, taskSelector: select)
                    }.frame(minHeight: 400)
#endif
#if os(iOS)
                    Priorities(priorities: today)
                    List {
                        DatedTaskList(listModel: $openModel)
                        DatedTaskList(listModel: $deadModel)
                        DatedTaskList(listModel: $closedModel)
                    }.frame(minHeight: 400)
#endif
                }
            }.background(Color.backgroundColor).frame(maxWidth: .infinity)
                .navigationDestination(isPresented: $showItem) {
                    if let item = selectedItem {
                        TaskItemView(item: item)
                    }
                }
#if os(macOS)
                .navigationSplitViewColumnWidth(min: 250, ideal: 400)
#endif
                .toolbar {
#if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: undo) {
                            Label("Undo", systemImage: imgUndo)
                        }.disabled(!canUndo)
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: redo) {
                            Label("Redo", systemImage: imgRedo)
                        }.disabled(!canRedo)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
#endif
                    ToolbarItem {
                        Button(action: review) {
                            Label("Review", systemImage: imgMagnifyingGlass)
                        }
                    }
                    ToolbarItem {
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                    
                }.background(Color.backgroundColor)
            
        } content: {
            List{
#if os(macOS)
                ListView(model: $listModel, taskSelector: select)
//                Section (header:
//                            VStack(alignment: .leading) {
//                    ForEach(selectedListHeader) { sec in
//                        sec.asText
//                    }
//                }) {
//                    ForEach(selectedList) { item in
//                        TaskAsLine(item:item).onTapGesture {
//                            selectedItem = item
//                        }
//                    }
//                }
#endif
            }.navigationSplitViewColumnWidth(min: 250, ideal: 400)
                .toolbar {
#if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                
#endif
                    
                }
        } detail: {
            if let detail = selectedItem {
                TaskItemView(item: detail)
            } else {
                Text("Select an item")
            }
        }.background(Color.backgroundColor)
            .sheet(isPresented: $showReviewDialog) {
                ReviewDialog(items: openItems)
            }
            .onAppear(perform: {
                today = loadPriorities(modelContext: modelContext)
                updateUndoRedoStatus()
            })
            .environment(today)
    }
    
    private func addItem() {
        withAnimation {
            let newItem = TaskItem()
            modelContext.insert(newItem)
            openModel.list.append(newItem)
#if os(macOS)
            select(sections: [secOpen], list: openItems, item: newItem)
#endif
#if os(iOS)
            selectedItem = newItem
            showItem = true
#endif
            updateUndoRedoStatus()
        }
    }
    
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
    
    private func review() {
        withAnimation {
            showReviewDialog = true
        }
    }
    
    //    private func deleteItems(offsets: IndexSet) {
    //        withAnimation {
    //            for index in offsets {
    //                modelContext.delete(openItems[index])
    //            }
    //        }
    //    }
}

#Preview {
    ContentView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
