//
//  DatedTaskList.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 17/12/2023.
//

import SwiftUI
import SwiftData



struct DatedTaskList: View {
    @Binding var listModel: ListViewModel
    @State var lastWeekModel: ListViewModel = ListViewModel(sections: [], list: [])
    @State var lastMonthModel: ListViewModel = ListViewModel(sections: [], list: [])
    @State var olderModel: ListViewModel = ListViewModel(sections: [], list: [])
    
#if os (iOS)
    init(listModel: Binding<ListViewModel>) {
        self._listModel = listModel
        self.lastWeekModel = ListViewModel(sections: listModel.wrappedValue.sections + [secLastWeek], list: [])
        self.lastMonthModel = ListViewModel(sections: listModel.wrappedValue.sections + [secLastMonth], list: [])
        self.olderModel = ListViewModel(sections: listModel.wrappedValue.sections + [secOlder], list: [])
    }
#endif
#if os(macOS)
    var taskSelector: TaskSelector
    
    init(listModel: Binding<ListViewModel>, taskSelector:  @escaping TaskSelector) {
        self._listModel = listModel
        self.lastWeekModel = ListViewModel(sections: listModel.wrappedValue.sections + [secLastWeek], list: [])
        self.lastMonthModel = ListViewModel(sections: listModel.wrappedValue.sections + [secLastMonth], list: [])
        self.olderModel = ListViewModel(sections: listModel.wrappedValue.sections + [secOlder], list: [])
        self.taskSelector = taskSelector
    }
#endif
    
    var lastWeek: [TaskItem] {
        return listModel.list.filter({$0.changed >= sevenDaysAgo})
    }
    var lastMonth: [TaskItem] {
        return listModel.list.filter({$0.changed < sevenDaysAgo && $0.changed >= thirtyDaysAgo})
    }
    var older: [TaskItem] {
        return listModel.list.filter({$0.changed < thirtyDaysAgo})
    }
    
    func update () {
        lastWeekModel.list = lastWeek
        lastMonthModel.list = lastMonth
        olderModel.list = older
    }
#if os(macOS)
    var body: some View {
        LinkToList(listModel: $listModel, taskSelector: taskSelector)
        LinkToList(listModel: $lastWeekModel, taskSelector: taskSelector)
        LinkToList(listModel: $lastMonthModel, taskSelector: taskSelector)
        if listModel.sections.first?.showOlder ?? true {
            LinkToList(listModel: $olderModel, taskSelector: taskSelector)
        }
    }
#endif
    
#if os(iOS)
    var body: some View {
        let _ = update()
        
        LinkToList(listModel: $listModel)
        LinkToList(listModel: $lastWeekModel)
        LinkToList(listModel: $lastMonthModel)
        if listModel.sections.first?.showOlder ?? true {
            LinkToList(listModel: $olderModel)
        }
    }
#endif
}


var agedList: [TaskItem] {
    let lastWeek1 = TaskItem(title: "3 days ago", changedDate: getDate(daysPrior: 3))
    let lastWeek2 = TaskItem(title: "5 days ago", changedDate: getDate(daysPrior: 5))
    let lastMonth1 = TaskItem(title: "11 days ago", changedDate: getDate(daysPrior: 11))
    let lastMonth2 = TaskItem(title: "22 days ago", changedDate: getDate(daysPrior: 22))
    let older1 = TaskItem(title: "31 days ago", changedDate: getDate(daysPrior: 31))
    let older2 = TaskItem(title: "101 days ago", changedDate: getDate(daysPrior: 101))
    let list = [lastWeek2,lastMonth2,lastWeek1,older1,older2,lastMonth1]
    return list
}
struct DatedTaskListHelper : View {
    @State var listModel = ListViewModel(sections: [secOpen], list: agedList)
    var body: some View {
        NavigationView {
            VStack{
#if os(macOS)
                DatedTaskList(listModel: $listModel, taskSelector:{a,b,c in debugPrint("triggered")})
#endif
#if os(iOS)
                DatedTaskList(listModel: $listModel)
#endif
            }
        }
        
    }
}


#Preview {
    return DatedTaskListHelper()
}
