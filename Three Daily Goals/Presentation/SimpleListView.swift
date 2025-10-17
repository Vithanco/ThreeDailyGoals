//
//  SimpleListView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 06/03/2024.
//

import SwiftUI
import tdgCoreMain

struct SimpleListView: View {
    let color: Color
    let itemList: [TaskItem]
    let headers: [ListHeader]
    let showHeaders: Bool
    let section: TaskSection
    let id: String
    @Environment(CloudPreferences.self) private var preferences
    @Environment(TimeProviderWrapper.self) var timeProviderWrapper: TimeProviderWrapper
    
    var body: some View {
        List {
            Section(
                header: VStack(alignment: .leading) {
                    HStack(spacing: 8) {
                        // Section icon with color
                        Image(systemName: section.image)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(color)
                            .frame(width: 20, height: 20)
                        
                        section.asText
                            .foregroundStyle(color)
                            .font(.system(size: 14, weight: .semibold))
                            .accessibilityIdentifier("ListView" + id)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            ) {
                if itemList.isEmpty {
                    Text("(No items found)")
                        .foregroundStyle(color)
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 20)
                } else {
                    ForEach(headers) { header in
                        let partialList = header.filter(items: itemList, timeProvider: timeProviderWrapper.timeProvider)
                        if partialList.count > 0 {
                            if showHeaders {
                                HStack(spacing: 8) {
                                    // Header icon with color
                                    Image(systemName: section.image)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(color)
                                        .frame(width: 16, height: 16)
                                    
                                    header.asText
                                        .foregroundStyle(color)
                                        .font(.system(size: 13, weight: .medium))
                                        .listRowSeparator(.hidden)
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                            ForEach(partialList) { item in
                                LinkToTask(item: item, list: item.state)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                            }
                        }
                    }
                    if itemList.count > 10 {
                        HStack(spacing: 8) {
                            Image(systemName: section.image)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(color)
                                .frame(width: 16, height: 16)
                            Text("\(itemList.count) tasks").font(.callout).foregroundStyle(color)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .listRowSeparator(.hidden)
        .background(Color.clear)
        .accessibilityIdentifier("scrollView_\(id)")
    }

}
//
//#Preview {
//    return SimpleListView(
//        itemList: dummy.dataManager.list(which: .dead),
//        headers: ListHeader.defaultListHeaders,
//        showHeaders: true,
//        section: secGraveyard,
//        id: "yeah"
//    )
//}
