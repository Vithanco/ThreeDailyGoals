//
//  SearchResultsView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 06/02/2026.
//

import SwiftUI
import tdgCoreMain
import tdgCoreWidget

struct SearchFieldView: View {
    @Environment(UIStateManager.self) private var uiState
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        @Bindable var uiState = uiState

        HStack(spacing: 8) {
            Image(systemName: imgSearch)
                .foregroundStyle(.secondary)
                .font(.body)
            TextField("Search tasks...", text: $uiState.searchText)
                .textFieldStyle(.plain)
                .focused($isTextFieldFocused)
                #if os(macOS)
                .onExitCommand {
                    uiState.stopSearch()
                }
                #endif
            if !uiState.searchText.isEmpty {
                Button(action: {
                    uiState.searchText = ""
                }) {
                    Image(systemName: imgXmarkCircle)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear search text")
            }
            Button(action: {
                uiState.stopSearch()
            }) {
                Text("Done")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Close search")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(colorScheme == .dark ? Color.neutral800 : Color.neutral100)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(colorScheme == .dark ? Color.neutral700 : Color.neutral300, lineWidth: 1)
        )
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

struct SearchResultsView: View {
    @Environment(UIStateManager.self) private var uiState
    @Environment(DataManager.self) private var dataManager
    @Environment(\.colorScheme) private var colorScheme

    private var searchResults: [TaskItem] {
        dataManager.searchTasks(query: uiState.searchText)
    }

    private var groupedResults: [(state: TaskItemState, tasks: [TaskItem])] {
        let results = searchResults
        let order: [TaskItemState] = [.priority, .open, .pendingResponse, .closed, .dead]
        return order.compactMap { state in
            let tasksForState = results.filter { $0.state == state }
            return tasksForState.isEmpty ? nil : (state: state, tasks: tasksForState)
        }
    }

    private var listBackground: some View {
        ZStack {
            if colorScheme == .dark {
                Color.neutral800.opacity(0.3)
            } else {
                Color.neutral200.opacity(0.9)
            }
        }
    }

    var body: some View {
        List {
            if uiState.searchText.isEmpty {
                Section {
                    Text("Type to search across all tasks")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            } else if groupedResults.isEmpty {
                Section {
                    Text("No results found")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            } else {
                ForEach(groupedResults, id: \.state) { group in
                    Section(
                        header: HStack(spacing: 8) {
                            Image(systemName: group.state.section.image)
                                .font(.body.weight(.medium))
                                .foregroundStyle(group.state.color)
                                .frame(width: 20, height: 20)

                            group.state.section.asText
                                .foregroundStyle(group.state.color)
                                .font(.subheadline.weight(.semibold))
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    ) {
                        ForEach(group.tasks) { item in
                            SearchResultRow(item: item)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .frame(minHeight: 145, maxHeight: .infinity)
        .background(listBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color.neutral700 : Color.neutral200, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? .black.opacity(0.1) : .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

private struct SearchResultRow: View {
    @Environment(UIStateManager.self) private var uiState
    @Bindable var item: TaskItem

    var body: some View {
        if isLargeDevice {
            Button(action: {
                uiState.select(which: item.state, item: item)
            }) {
                TaskAsLine(item: item)
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            NavigationLink(value: item) {
                TaskAsLine(item: item)
            }
        }
    }
}
