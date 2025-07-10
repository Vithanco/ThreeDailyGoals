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
    let section: TaskSection
    let id: String
    @Bindable var model: TaskManagerViewModel

    var body: some View {
        List {
            Section(
                header: VStack(alignment: .leading) {
                    HStack {
                        section.asText.foregroundStyle(model.accentColor).listRowSeparator(.hidden)
                            .accessibilityIdentifier("ListView" + id)
                    }
                }
            ) {
                if itemList.isEmpty {
                    Spacer(minLength: 20)
                    Text("(No items found)").foregroundStyle(model.accentColor).frame(maxWidth: .infinity)
                    Spacer(minLength: 20)
                } else {
                    if !showHeaders {
                        Spacer().frame(height: 10)
                    }

                    let allItems = headers.flatMap { header in
                        header.filter(items: itemList)
                    }

                    ForEach(headers) { header in
                        let partialList = header.filter(items: itemList)
                        if partialList.count > 0 {
                            if showHeaders {
                                header.asText
                                    .foregroundStyle(model.accentColor)
                                    .listRowSeparator(.hidden)
                            }
                            ForEach(partialList) { item in
                                LinkToTask(model: model, item: item, list: item.state)
                                    .listRowSeparator(
                                        !showHeaders && allItems.first?.id == item.id ? .hidden : .visible
                                    )
                            }
                        }
                    }
                    if itemList.count > 10 {
                        Text("\(itemList.count) tasks").font(.callout).foregroundStyle(model.accentColor)
                            .listRowSeparator(.hidden)
                    }
                }
            }

        }.accessibilityIdentifier("scrollView_\(id)")
    }

}

#Preview {
    let dummy = dummyViewModel()
    return SimpleListView(
        itemList: dummy.list(which: .dead),
        headers: ListHeader.defaultListHeaders,
        showHeaders: true,
        section: secGraveyard,
        id: "yeah",
        model: dummy
    )
}
