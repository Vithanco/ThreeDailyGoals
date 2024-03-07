//
//  SimpleListView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 06/03/2024.
//

import SwiftUI

struct SimpleListView: View {
    let itemList: [TaskItem]
    let headers: [ListHeader]
    let showHeaders: Bool
    @Bindable var model: TaskManagerViewModel
    
    var body: some View {
            ForEach(headers) {header in
                let partialList = header.filter(items: itemList)
                if partialList.count > 0 {
                    if showHeaders {
                        header.asText
                            .foregroundStyle(model.accentColor)
                            .listRowSeparator(.hidden)
                    }
                    ForEach(partialList) { item in
                        LinkToTask(model: model,item: item, list: item.state).listRowSeparator(.visible)
                    }
                }
            }
            if itemList.count > 10 {
                Text("\(itemList.count) tasks").font(.callout).foregroundStyle(model.accentColor)
                    .listRowSeparator(.hidden)
            }
    }
    
}

#Preview {
    let dummy = dummyViewModel()
    return SimpleListView(itemList: dummy.list(which: .open), headers: defaultListHeaders, showHeaders: true, model: dummy)
}
