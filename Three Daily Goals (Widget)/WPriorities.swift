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
    let priorities: [TaskItem]
    
    var body: some View {
        VStack(alignment: .leading) {
            Section (header: Text("\(Image(systemName: imgToday)) Today").font(.title).foregroundStyle(Color.mainColor)){
            let prios = priorities.filter({$0.isOpenOrPriority})
                let count = prios.count
                    AWPriority(image: imgPriority1, item: count > 0 ? prios[0] : nil)
                    AWPriority(image: imgPriority2, item: count > 1 ? prios[1] : nil)
                    AWPriority(image: imgPriority3, item: count > 2 ? prios[2] : nil)
                
            }
        }
    }
}

#Preview {
    WPriorities(priorities: TaskManagerViewModel(modelContext: TestStorage()).priorityTasks)
}
