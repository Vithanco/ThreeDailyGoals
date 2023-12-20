//
//  LinkToList.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI

struct LinkToList: View {
    let sections: [TaskSection]
    let items: [TaskItem]
    var taskSelector : TaskSelector
    
//    @Binding var selectedList: [TaskItem]
//    @Binding var selectedListHeader : [TaskSection]
    var body: some View {
            HStack {
                sections.last!.asText
                Spacer()
                Text(items.count.description)
            }.onTapGesture {
                taskSelector(sections,items,items.first)
            }
    }
}

#Preview {
    LinkToList(sections: [secClosed,secLastWeek], items: [TaskItem(), TaskItem()], taskSelector: {a,b,c in debugPrint("triggered")})
}
