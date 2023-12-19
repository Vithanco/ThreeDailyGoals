//
//  Priorities.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 18/12/2023.
//

import SwiftUI


struct APriority: View {
    var image: String
    var item: TaskItem?
    var body: some View {
        HStack {
            Image(systemName: image)
            if let item = item {
                LinkToTask(item: item)
            }else {
              Text("(missing)")
            }
        }
    }
}

struct Priorities: View {
    let priorities: DailyTasks
    
    var body: some View {
        List {
            Section (header: Text("\(Image(systemName: "exclamationmark.square.fill")) Today").font(.title).foregroundStyle(mainColor)){
                if let prios = priorities.priorities {
                    let count = prios.count
                    APriority(image: "1.square.fill", item: count > 0 ? prios[0] : nil)
                    APriority(image: "2.square.fill", item: count > 1 ? prios[1] : nil)
                    APriority(image: "3.square.fill", item: count > 2 ? prios[2] : nil)
                    let others = prios.dropFirst(3)
                    ForEach (others) {priority in
                        APriority(image: "x.square.fill",item: priority)
                    }
                }
            }
        }.frame(maxHeight: .infinity)
    }
}

#Preview {
    Priorities(priorities: DailyTasks())
}
