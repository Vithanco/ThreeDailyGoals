//
//  WPriorities.swift
//  Three Daily Goals (Widget)Extension
//
//  Created by Klaus Kneupner on 21/12/2023.
//


import Foundation
import SwiftUI


struct AWPriority: View {
    var image: String
    var item: TaskItem?
    var body: some View {
        HStack {
            Image(systemName: image)
            if let item = item {
                HStack {
                    Text(item.title)
                }
            }else {
              Text("(missing)")
            }
        }
    }
}

struct WPriorities: View {
    let priorities: DailyTasks
    
    var body: some View {
//            Section (header: Text("\(Image(systemName: imgToday)) Today").font(.title).foregroundStyle(mainColor)){
                if let prios = priorities.priorities {
                    let count = prios.count
                    AWPriority(image: imgPriority1, item: count > 0 ? prios[0] : nil)
                    AWPriority(image: imgPriority2, item: count > 1 ? prios[1] : nil)
                    AWPriority(image: imgPriority3, item: count > 2 ? prios[2] : nil)
//                    let others = prios.dropFirst(3)
//                    ForEach (others) {priority in
//                        AWPriority(image: imgPriorityX,item: priority)
//                    }
                }
//            }
    }
}

#Preview {
    WPriorities(priorities: DailyTasks())
}
