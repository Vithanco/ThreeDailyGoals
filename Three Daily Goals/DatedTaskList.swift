//
//  DatedTaskList.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 17/12/2023.
//

import SwiftUI
import SwiftData


let secondaryColor = Color(red: 255.0/255.0, green: 128.0/255.0, blue: 0/255.0, opacity: 1.0)

func getDate (daysPrior: Int) -> Date {
    let exact = Calendar.current.date(byAdding: .day, value: -1 * daysPrior, to: Date.now) ?? Date.now
    return Calendar.current.startOfDay(for: exact)
}

struct DatedTaskList: View {
    let list : [TaskItem]
    let sevenDaysAgo = getDate(daysPrior: 7)
    let thirtyDaysAgo = getDate(daysPrior: 30)
    
    var lastWeek: [TaskItem] {
        return list.filter({$0.changed >= sevenDaysAgo})
    }
    var lastMonth: [TaskItem] {
        return list.filter({$0.changed < sevenDaysAgo && $0.changed >= thirtyDaysAgo})
    }
    var older: [TaskItem] {
        return list.filter({$0.changed < thirtyDaysAgo})
    }
    
    var body: some View {
        Section(header: Text("Last Week").font(.callout).foregroundStyle(secondaryColor)){
            ForEach(lastWeek) { item in
                NavigationLink {
                    TaskItemView(item: item)
                } label: {
                    Text(item.title)
                }
            }
        }
        Section(header: Text("Last Month").font(.callout).foregroundStyle(secondaryColor)){
            ForEach(lastMonth) { item in
                NavigationLink {
                    TaskItemView(item: item)
                } label: {
                    Text(item.title)
                }
            }
        }
        Section(header: Text("Older").font(.callout).foregroundStyle(secondaryColor)){
            ForEach(older) { item in
                NavigationLink {
                    TaskItemView(item: item)
                } label: {
                    Text(item.title)
                }
            }
        }
    }
}


struct DatedTaskListHelper : View {
    @State var list: [TaskItem]
    var body: some View {
        NavigationView {
            VStack{
                DatedTaskList(list: list)
            }
        }
        
    }
}


#Preview {
//    do{
//        let config = ModelConfiguration(isStoredInMemoryOnly: true)
//        let container = try ModelContainer(for: TaskItem.self, configurations: config)
        let lastWeek1 = TaskItem()
        lastWeek1.title = "3 days ago"
        lastWeek1.changed = getDate(daysPrior: 3)
        let lastWeek2 = TaskItem()
        lastWeek2.title = "5 days ago"
        lastWeek2.changed = getDate(daysPrior: 5)
        let lastMonth1 = TaskItem()
        lastMonth1.title = "11 days ago"
        lastMonth1.changed = getDate(daysPrior: 11)
        let lastMonth2 = TaskItem()
        lastMonth2.title = "22 days ago"
        lastMonth2.changed = getDate(daysPrior: 22)
        let older1 = TaskItem()
        older1.title = "31 days ago"
        older1.changed = getDate(daysPrior: 31)
        let older2 = TaskItem()
        older2.title = "101 days ago"
        older2.changed = getDate(daysPrior: 101)
    var list = [lastWeek2,lastMonth2,lastWeek1,older1,older2,lastMonth1]
        return DatedTaskListHelper(list: list)
//            .modelContainer(container)
//    } catch {
//        fatalError("Failed to create model container.")
//    }
//    
//    
}
