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
    @Query private var items: [TaskItem]
//    @Query(filter: #Predicate<TaskItem> {
//        item in
//        item.state == TaskItemState.open
//    }) var openItems: [TaskItem]
    
    var openItems: [TaskItem] {
        return items.filter({$0.state == .open})
    }
    
    var closedItems: [TaskItem]{
        return items.filter({$0.state == .closed})
    }
    
    var deadItems: [TaskItem]{
        return items.filter({$0.state == .graveyard})
    }
    
    
    var body: some View {
        
        NavigationSplitView {
            VStack{
                List {
                    Section( header: StateViewHelper(state: .open)){
                        ForEach(openItems) { item in
                            NavigationLink {
                                TaskItemView(item: item)
                            } label: {
                                Text(item.title)
                            }
                        }
//                        .onDelete(perform: deleteItems)
                    }
                }
                List {
                    Section( header: StateViewHelper(state: .graveyard)){
                        DatedTaskList(list: deadItems)
                    }
                }
                List {
                    Section( header: StateViewHelper(state: .closed)){
                        DatedTaskList(list: closedItems)
                    }
                }
            }.background(.white)
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 250, ideal: 400)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }.background(.white)
    }

    private func addItem() {
        withAnimation {
            let newItem = TaskItem()
            modelContext.insert(newItem)
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
