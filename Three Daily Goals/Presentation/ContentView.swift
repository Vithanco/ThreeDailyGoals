//
//  ContentView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import SwiftUI
import SwiftData

typealias TaskSelector = ([TaskSection],[TaskItem],TaskItem?) -> Void
typealias OnSelectItem = (TaskItem) -> Void

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.changed, order: .reverse) private var items: [TaskItem]
    @Query private var days: [DailyTasks]
    
    @State private var selectedList: [TaskItem] = []
    @State private var selectedItem: TaskItem? = nil
    @State private var selectedListHeader: [TaskSection] = []
    
    @State var showReviewDialog: Bool = false
    //    @Query(filter: #Predicate<TaskItem> {
    //        item in
    //        item.state == TaskItemState.open
    //    }) var openItems: [TaskItem]
    
    var openItems: [TaskItem] {
        return items.filter({$0.state == .open}).sorted()
    }
    
    var closedItems: [TaskItem]{
        return items.filter({$0.state == .closed}).sorted()
    }
    
    var deadItems: [TaskItem]{
        return items.filter({$0.state == .graveyard}).sorted()
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
    
    func select(sections: [TaskSection], list: [TaskItem], item: TaskItem?) {
        withAnimation{
                selectedListHeader = sections
                selectedList = list
//                if let item = item {
//                    assert(list.contains(item))
//                }
                selectedItem = item
        }
    }
    
    var body: some View {
        
        NavigationSplitView {
            VStack(alignment: .leading){
                
                Priorities(priorities: today,taskSelector: select)
                List {
                    DatedTaskList(section: secOpen, list: openItems, taskSelector: select)
                    DatedTaskList(section: secGraveyard, list: deadItems, taskSelector: select)
                    DatedTaskList(section: secClosed, list: closedItems, taskSelector: select)
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
            List {
                Section (header:
                            VStack(alignment: .leading) {
                                ForEach(selectedListHeader) { sec in
                                    sec.asText
                                }
                            }) {
                    ForEach(selectedList) { item in
                        Text(item.title).onTapGesture {
                            selectedItem = item
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 400)
                .toolbar {
#if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
#endif
                    ToolbarItem {
                        Button(action: review) {
                            Label("Review", systemImage: imgMagnifyingGlass)
                        }
                    }
                }
        } detail: {
            if let detail = selectedItem {
                TaskItemView(item: detail)
            } else {
                Text("Select an item")
            }
        }.background(.white)
            .sheet(isPresented: $showReviewDialog) {
                ReviewDialog(items: openItems)
            }
            .environment(today)
    }
    
    private func addItem() {
            let newItem = TaskItem()
            modelContext.insert(newItem)
            select(sections: [secOpen], list: openItems, item: newItem)
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
