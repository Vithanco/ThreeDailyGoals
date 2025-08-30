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
    @Environment(CloudPreferences.self) private var preferences

    // Get the list color based on the section
    private var listColor: Color {
        switch section.text {
        case "Today's Goals": return .orange
        case "Open": return .blue
        case "Pending Response": return .yellow
        case "Closed": return .green
        case "Graveyard": return .gray
        case "Due Soon": return .orange
        default: return .orange
        }
    }
    
    public static func priorityView(dataManager: DataManager) ->  SimpleListView {
        return SimpleListView(
            itemList: dataManager.list(which: .priority),
            headers: TaskItemState.priority.subHeaders,
            showHeaders: false, // Don't show headers for priority list
            section: TaskItemState.priority.section,
            id: TaskItemState.priority.getListAccessibilityIdentifier
        )
    }

    var body: some View {
        List {
            Section(
                header: VStack(alignment: .leading) {
                    HStack(spacing: 8) {
                        // Section icon with color
                        Image(systemName: section.image)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(listColor)
                            .frame(width: 20, height: 20)
                        
                        section.asText
                            .foregroundStyle(listColor)
                            .font(.system(size: 14, weight: .semibold))
                            .accessibilityIdentifier("ListView" + id)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            ) {
                if itemList.isEmpty {
                    Text("(No items found)")
                        .foregroundStyle(listColor)
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 20)
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
                                HStack(spacing: 8) {
                                    // Header icon with color
                                    Image(systemName: section.image)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(listColor)
                                        .frame(width: 16, height: 16)
                                    
                                    header.asText
                                        .foregroundStyle(listColor)
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
                        Text("\(itemList.count) tasks").font(.callout).foregroundStyle(listColor)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
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
