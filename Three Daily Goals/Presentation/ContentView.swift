//
//  ContentView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import SwiftUI
import SwiftData
import os

struct ContentView: View {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ContentView.self)
    )
    
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.changed, order: .reverse) private var items: [TaskItem]
    @State private var selectedItem: TaskItem? = nil
    @State private var showItem: Bool = false
    
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
    
    @State var today: DailyTasks? = nil
    
    func loadPriorities() -> DailyTasks {
        let fetchDescriptor = FetchDescriptor<DailyTasks>()
        
        do {
            let days = try modelContext.fetch(fetchDescriptor)
            if days.count > 1 {
                logger.error("days has \(days.count) entries! Why?")
                for d in days {
                    modelContext.delete(d)
                }
            }
            if let result = days.first {
                return result
            }
        }
        catch {
            logger.warning("no data available?")
        }
        let new = DailyTasks()
        modelContext.insert(new)
        return new
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
                if let today = today {
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
                }
            }.background(.white).frame(maxWidth: .infinity)
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
            .onAppear(perform: {today = loadPriorities()})
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
            showItem = true
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
