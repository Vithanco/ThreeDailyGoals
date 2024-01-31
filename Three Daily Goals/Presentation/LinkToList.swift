//
//  LinkToList.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI
import SwiftData

private struct ListLabel :View{
    var name: Text
    var count: Int
    var showCount: Bool
    
    var body: some View {
        if showCount {
            HStack {
                name
                Spacer()
                Text(count.description)
            }
        } else {
            HStack {
                name
                Spacer()
            }
        }
    }
}

struct LinkToList: View {
    @State var whichList: TaskItemState
    @Bindable var model: TaskManagerViewModel
    
    var body: some View {
#if os(iOS)
        NavigationLink {
            ListView(whichList: whichList, model: model)
        } label: {
            ListLabel(name: whichList.section.asText, count:model.list(which: whichList).count, showCount: whichList.showCount).foregroundStyle(model.accentColor)
        }
#endif
#if os(macOS)
        ListLabel(name: whichList.section.asText, count:model.list(which: whichList).count, showCount: whichList.showCount)
            .onTapGesture {
                model.select(which: whichList,item: model.list(which: whichList).first)
            }
            .dropDestination(for: String.self){
                items, location in
                for item in items.compactMap({model.findTask(withID: $0)}) {
                    model.move(task: item, to: whichList)
                }
                return true
            }
            .foregroundStyle(model.accentColor)
#endif
    }
}
 

#Preview {
    LinkToList(whichList: .open, model: TaskManagerViewModel(modelContext: TestStorage()))
}


