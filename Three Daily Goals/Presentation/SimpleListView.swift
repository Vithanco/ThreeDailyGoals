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
        List{
            Section (header: VStack(alignment: .leading) {
                HStack{
                    section.asText.foregroundStyle(model.accentColor).listRowSeparator(.hidden).accessibilityIdentifier(id)
                    //                        Text(" - \(itemList.count)").font(.title).foregroundStyle(model.accentColor)
                }
            }) {
                if itemList.isEmpty {
                    Spacer(minLength: 20)
                    Text("(No items found)").foregroundStyle(model.accentColor).frame(maxWidth: .infinity)
                    Spacer(minLength: 20)
                } else {
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
            
        }
    }
        
    }
    
    #Preview {
        let dummy = dummyViewModel()
        return SimpleListView(itemList: dummy.list(which: .open), headers: defaultListHeaders, showHeaders: true, section: secOpen, id: "yeah", model: dummy)
    }
