//
//  ReviewDialog.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI

struct ReviewDialog: View {
    @EnvironmentObject var today : DailyTasks
    var items: [TaskItem]
    var body: some View {
        VStack {
            Text("Review your Tasks!").font(.caption).foregroundStyle(mainColor)
            Text("The previous Tasks were: ")
            
        }
        
    }
}

#Preview {
    let lastWeek1 = TaskItem()
    lastWeek1.title = "3 days ago"
    lastWeek1.setChangedDate(getDate(daysPrior: 3))
    let lastWeek2 = TaskItem()
    lastWeek2.title = "5 days ago"
    lastWeek2.setChangedDate(getDate(daysPrior: 5))
    let lastMonth1 = TaskItem()
    lastMonth1.title = "11 days ago"
    lastMonth1.setChangedDate(getDate(daysPrior: 11))
    let lastMonth2 = TaskItem()
    lastMonth2.title = "22 days ago"
    lastMonth2.setChangedDate(getDate(daysPrior: 22))
    let older1 = TaskItem()
    older1.title = "31 days ago"
    older1.setChangedDate(getDate(daysPrior: 31))
    let older2 = TaskItem()
    older2.title = "101 days ago"
    older2.setChangedDate(getDate(daysPrior: 101))
    let list = [lastWeek2,lastMonth2,lastWeek1,older1,older2,lastMonth1]
    return ReviewDialog(items: list).environment(DailyTasks())
}
