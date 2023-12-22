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
    @Query(sort: \TaskItem.changed, order: .reverse) private var items: [TaskItem]
    @Query private var days: [DailyTasks]
    @State private var selectedItem: TaskItem? = nil
    
    
    
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
    
#if os(macOS)
    @State private var selectedList: [TaskItem] = []
    @State private var selectedListHeader: [TaskSection] = []
    
    func select(sections: [TaskSection], list: [TaskItem], item: TaskItem?) {
        withAnimation{
            selectedListHeader = sections
            selectedList = list
            selectedItem = item
        }
    }
#endif
    
    var body: some View {
        
        NavigationSplitView {
            VStack(alignment: .leading){
#if os(macOS)
                Priorities(priorities: today,taskSelector: select)
                List {
                    DatedTaskList(section: secOpen, list: openItems, taskSelector: select)
                    DatedTaskList(section: secGraveyard, list: deadItems, taskSelector: select)
                    DatedTaskList(section: secClosed, list: closedItems, taskSelector: select)
                }.frame(minHeight: 400)
#endif
#if os(iOS)
                Priorities(priorities: today)
                List {
                    DatedTaskList(section: secOpen, list: openItems)
                    DatedTaskList(section: secGraveyard, list: deadItems)
                    DatedTaskList(section: secClosed, list: closedItems)
                }.frame(minHeight: 400)
#endif
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
#if os(macOS)
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
#endif
            }.navigationSplitViewColumnWidth(min: 250, ideal: 400)
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
        withAnimation {
            let newItem = TaskItem()
            modelContext.insert(newItem)
#if os(macOS)
            select(sections: [secOpen], list: openItems, item: newItem)
#endif
#if os(iOS)
            selectedItem = newItem
#endif
        }
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
