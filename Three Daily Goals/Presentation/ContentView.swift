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
    @Query private var days: [DailyTasks]
    
    @State var selectedItem: TaskItem?
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
    
    var today: DailyTasks {
        if let existing = days.first(where: {$0.day.isToday }) {
            return  existing
        }
        // need to create a new Version
        let newItem = DailyTasks()
        modelContext.insert(newItem)
        assert(newItem.day.isToday)
        return newItem
    }
    
    
    var body: some View {
        
        NavigationSplitView {
            VStack(alignment: .leading){
                Priorities(priorities: today)
                List {
                    DatedTaskList(section: secOpen, list: openItems)
                    DatedTaskList(section: secGraveyard, list: deadItems)
                    DatedTaskList(section: secClosed, list: closedItems)
                }.frame(minHeight: 400)
            }.background(.white).frame(maxWidth: .infinity)
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
                }.background(.white)
            
        } content: {
            List{
                
            }
        } detail: {
            if let detail = selectedItem {
                TaskItemView(item: detail)
            } else {
                Text("Select an item")
            }
        }.background(.white)
    }
    
    private func addItem() {
        withAnimation {
            let newItem = TaskItem()
            modelContext.insert(newItem)
            selectedItem = newItem
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
