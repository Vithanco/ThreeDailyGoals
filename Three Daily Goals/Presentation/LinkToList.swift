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
    var body: some View {
        NavigationLink {
            TaskListView(section: sections, items: items)
        } label: {
            HStack {
                sections.last!.asText
                Spacer()
                Text(items.count.description)
            }
        }
    }
}

#Preview {
    LinkToList(sections: [secClosed,secLastWeek], items: [TaskItem(), TaskItem()])
}
