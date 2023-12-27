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
    @Binding var listModel: ListViewModel
#if os(macOS)
    var taskSelector : TaskSelector
#endif
    var body: some View {
#if os(iOS)
        NavigationLink {
            ListView(model: $listModel)
        } label: {
            Label(name: listModel.sections.last?.asText ?? Text("Missing"), count:listModel.list.count)
        }
#endif
#if os(macOS)
        Label(name: listModel.sections.last?.asText ?? Text("Missing"), count:listModel.list.count)
            .onTapGesture {
                taskSelector(listModel.sections,listModel.list,listModel.list.first)
            }
#endif
    }
}



struct LinkToListHelper : View {
    @State var model = ListViewModel( sections: [secClosed,secLastWeek], list: [TaskItem(), TaskItem()])
    
    var body: some View {
#if os(macOS)
        LinkToList(listModel: $model, taskSelector: {a,b,c in debugPrint("triggered")})
#endif
#if os(iOS)
        LinkToList(listModel: $model)
#endif
    }
}

#Preview {
    LinkToListHelper()
}


