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
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .toolbar {
                
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
    return ReviewDialog(items: list).environment(DailyTasks())
}
