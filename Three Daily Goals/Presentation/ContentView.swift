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
        //        let _ = model.updateModels()
        SingleView{
            NavigationSplitView {
                LeftSideView(model: model).background(Color.background).frame(maxHeight: .infinity)
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
                        
                    }.background(Color.background)
                
            } content: {
                SingleView{
#if os(macOS)
                    ListView( model: model).background(Color.background)
#endif
#if os(iOS)
                    Text("Placeholder")
#endif
                }.background(Color.background)
                    .navigationSplitViewColumnWidth(min: 250, ideal: 400)
                //            .toolbar {
                //
                //            }
            }
        detail: {
            if let detail = model.selectedItem {
                TaskItemView(model: model, item: detail)
            } else {
                Text("Select an item")
            }
        }.background(Color.background)
                .sheet(isPresented: $model.showReviewDialog) {
                    ReviewDialog(model: model)
                }
                .onAppear(perform: {
                    model.loadToday()
                })
                .environment(model.today)
        }.background(Color.background)
    }
    
    private func addItem() {
        let _ = withAnimation {
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
}

#Preview {
    ContentView(modelContext: sharedModelContainer(inMemory: true).mainContext)
    
}
