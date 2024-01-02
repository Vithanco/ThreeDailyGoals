//
//  ContentView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import SwiftUI
import SwiftData


struct SingleView<Content: View>: View {
    
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
    }
}

struct ContentView: View {
    @State var model : TaskManagerViewModel
    
    
    init(modelContext: ModelContext){
        model = TaskManagerViewModel(modelContext: modelContext)
    }
    
    var body: some View {
        let _ = model.updateModels()
        NavigationSplitView {
            VStack(alignment: .leading){
                ListView(whichList: .priorities, model: model)
                List {
                    LinkToList(whichList: .openItems, model: model)
                    LinkToList(whichList: .closedItems, model: model)
                    LinkToList(whichList: .deadItems, model: model)
                }.frame(minHeight: 400)
            }.background(Color.backgroundColor).frame(maxWidth: .infinity)
                .navigationDestination(isPresented: $model.showItem) {
                    if let item = model.selectedItem {
                        TaskItemView(item: item)
                    }
                }
#if os(macOS)
                .navigationSplitViewColumnWidth(min: 300, ideal: 400)
#endif
                .toolbar {
                    ToolbarItem {
                        Button(action: undo) {
                            Label("Undo", systemImage: imgUndo)
                        }.disabled(!model.canUndo)
                    }
                    ToolbarItem {
                        Button(action: redo) {
                            Label("Redo", systemImage: imgRedo)
                        }.disabled(!model.canRedo)
                    }
#if os(iOS)
                    ToolbarItem {
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
            SingleView{
#if os(macOS)
                ListView( model: model)
#endif
#if os(iOS)
                Text("Placeholder")
#endif
            }
            
            .navigationSplitViewColumnWidth(min: 250, ideal: 400)
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
            }
        }
    detail: {
        if let detail = model.selectedItem {
            TaskItemView(item: detail)
        } else {
            Text("Select an item")
        }
    }.background(Color.backgroundColor)
            .sheet(isPresented: $model.showReviewDialog) {
                ReviewDialog(model: model)
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
