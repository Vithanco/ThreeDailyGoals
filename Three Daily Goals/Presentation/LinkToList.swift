//
//  LinkToList.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI

private struct Label :View{
    var name: Text
    var count: Int
    var body: some View {
        HStack {
            name
            Spacer()
            Text(count.description)
        }
    }
}

struct LinkToList: View {
    let sections: [TaskSection]
    let items: [TaskItem]
#if os(macOS)
    var taskSelector : TaskSelector
#endif
    var body: some View {
#if os(iOS)
        NavigationLink {
            TaskListView(section: sections, items: items)
        } label: {
            Label(name: sections.last!.asText, count:items.count)
        }
#endif
#if os(macOS)
        Label(name: sections.last!.asText, count:items.count)
            .onTapGesture {
                taskSelector(sections,items,items.first)
            }
#endif
    }
}


#if os(macOS)
#Preview {
    LinkToList(sections: [secClosed,secLastWeek], items: [TaskItem(), TaskItem()], taskSelector: {a,b,c in debugPrint("triggered")})
}
#endif
#if os(iOS)
#Preview {
    LinkToList(sections: [secClosed,secLastWeek], items: [TaskItem(), TaskItem()])
}
#endif

