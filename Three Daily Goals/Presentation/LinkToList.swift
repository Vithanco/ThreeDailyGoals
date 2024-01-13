//
//  LinkToList.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI
import SwiftData

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
    @State var whichList: ListChooser
    @Bindable var model: TaskManagerViewModel
    
    var body: some View {
#if os(iOS)
        NavigationLink {
            ListView(whichList: whichList, model: model)
        } label: {
            Label(name: whichList.sections.first?.asText ?? Text("Missing"), count:model.list(which: whichList).count)
        }
#endif
#if os(macOS)
        Label(name: whichList.sections.first?.asText ?? Text("Missing"), count:model.list(which: whichList).count)
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
#endif
    }
}
 

#Preview {
    LinkToList(whichList: .openTasks, model: TaskManagerViewModel(modelContext: TestStorage()))
}


