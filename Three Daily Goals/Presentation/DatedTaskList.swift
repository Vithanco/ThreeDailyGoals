//
//  DatedTaskList.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 17/12/2023.
//

import SwiftUI
import SwiftData



struct DatedTaskList: View {
    let section : TaskSection
    let list : [TaskItem]
    let sevenDaysAgo = getDate(daysPrior: 7)
    let thirtyDaysAgo = getDate(daysPrior: 30)
    var taskSelector: TaskSelector
    
    
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
        LinkToList(sections: [section], items: list, taskSelector: taskSelector)
        LinkToList(sections: [section, secLastWeek], items: lastWeek, taskSelector: taskSelector)
        LinkToList(sections: [section, secLastMonth], items: lastMonth, taskSelector: taskSelector)
        if section.showOlder {
            LinkToList(sections: [section, secOlder], items: older, taskSelector: taskSelector)
        }
    }
}


struct DatedTaskListHelper : View {
    @State var list: [TaskItem]
    var body: some View {
        NavigationView {
            VStack{
                DatedTaskList(section: secOpen, list: list, taskSelector:{a,b,c in debugPrint("triggered")})
            }
        }
        
    }
}


#Preview {
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
}
