//
//  Priorities.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 18/12/2023.
//

import SwiftUI

#if os(macOS)
struct APriority: View {
    var image: String
    var item: TaskItem?
    var onSelectItem : OnSelectItem
    var body: some View {
        HStack {
            Image(systemName: image)
            if let item = item {
                HStack {
                    Text(item.title).strikethrough(item.isClosed, color: .mainColor)
                    
                }.onTapGesture {
                    onSelectItem(item)
                }
            }else {
              Text("(missing)")
            }
        }
    }
}

struct Priorities: View {
    let priorities: DailyTasks
    var taskSelector : TaskSelector
    func select(_ item: TaskItem) {
        taskSelector([secToday], priorities.priorities ?? [], item)
    }
    var body: some View {
        List {
            Section (header: Text("\(Image(systemName: imgToday)) Today")
                    .font(.title)
                    .foregroundStyle(Color.mainColor)
                    .onTapGesture {
                        taskSelector([secToday],priorities.priorities ?? [],priorities.priorities?.first)
                    }){
                if let prios = priorities.priorities {
                    let count = prios.count
                    let others = prios.dropFirst(3)
                    APriority(image: imgPriority1, item: count > 0 ? prios[0] : nil, onSelectItem: select)
                    APriority(image: imgPriority2, item: count > 1 ? prios[1] : nil, onSelectItem: select)
                    APriority(image: imgPriority3, item: count > 2 ? prios[2] : nil, onSelectItem: select)
                    ForEach (others) {priority in
                        APriority(image: imgPriorityX,item: priority, onSelectItem: select)
                    }
                }
            }
        }.frame(maxHeight: .infinity)
    }
}


#Preview {
    Priorities(priorities: DailyTasks(), taskSelector: {a,b,c in debugPrint("triggered")})
}
#endif

#if os(iOS)
struct APriority: View {
    var image: String
    var item: TaskItem?
    var body: some View {
        HStack {
            Image(systemName: image)
            if let item = item {
                LinkToTask(item: item).strikethrough( item.isClosed, color: Color.mainColor)
            }else {
              Text("(missing)")
            }
        }
    }
}
struct Priorities: View {
    let priorities: DailyTasks
    @State var listModel = ListViewModel(sections:[secToday], list : [])
    
    func updateModel() {
        listModel.list = priorities.priorities ?? []
    }
    var body: some View {
        List {
            Section (header: LinkToList(listModel: $listModel)
                .font(.title)
                .foregroundStyle(Color.mainColor)){
                if let prios = priorities.priorities {
                    let count = prios.count
                    let others = prios.dropFirst(3)
                    APriority(image: imgPriority1, item: count > 0 ? prios[0] : nil)
                    APriority(image: imgPriority2, item: count > 1 ? prios[1] : nil)
                    APriority(image: imgPriority3, item: count > 2 ? prios[2] : nil)
                    ForEach (others) {priority in
                        APriority(image: imgPriorityX,item: priority)
                    }
                }
            }
        }.frame(maxHeight: .infinity)
    }
}

#Preview {
    Priorities(priorities: DailyTasks())
}
#endif

