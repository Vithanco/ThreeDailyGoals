//
//  ContentView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State var model : TaskManagerViewModel
     
    
    init(modelContext: ModelContext){
        model = TaskManagerViewModel(modelContext: modelContext)
    }

    var body: some View {
        let _ = model.updateModels()
        NavigationSplitView {
            VStack(alignment: .leading){
                if let today = model.today {
#if os(macOS)
                    Priorities(priorities: today,taskSelector: select)
                    List {
                        LinkToList(listModel: $openModel, taskSelector: select)
                        LinkToList(listModel: $deadModel, taskSelector: select)
                        LinkToList(listModel: $closedModel, taskSelector: select)
                    }.frame(minHeight: 400)
#endif
#if os(iOS)
                    Priorities(priorities: today)
                    List {
                        LinkToList(listModel: $model.openModel)
                        LinkToList(listModel: $model.deadModel)
                        LinkToList(listModel: $model.closedModel)
                    }.frame(minHeight: 400)
#endif
                }
            }.background(Color.backgroundColor).frame(maxWidth: .infinity)
                .navigationDestination(isPresented: $model.showItem) {
                    if let item = model.selectedItem {
                        TaskItemView(item: item)
                    }
                }
#if os(macOS)
                .navigationSplitViewColumnWidth(min: 250, ideal: 400)
#endif
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: undo) {
                            Label("Undo", systemImage: imgUndo)
                        }.disabled(!model.canUndo)
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: redo) {
                            Label("Redo", systemImage: imgRedo)
                        }.disabled(!model.canRedo)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
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
            if let detail = model.selectedItem {
                TaskItemView(item: detail)
            } else {
                Text("Select an item")
            }
        }.background(Color.backgroundColor)
            .sheet(isPresented: $model.showReviewDialog) {
                ReviewDialog(items: model.openItems)
            }
            .onAppear(perform: {
                model.loadToday()
            })
            .environment(model.today)
    }
    
  
    private func addItem() {
        withAnimation {
            model.addItem()
        }
    }
    
    private func undo() {
        withAnimation {
            model.undo()
        }
    }
    
    private func redo() {
        withAnimation {
            model.redo()
        }
      }


    
    private func review() {
        withAnimation {
            model.showReviewDialog = true
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
    ContentView(modelContext: sharedModelContainer(inMemory: true).mainContext)

}
