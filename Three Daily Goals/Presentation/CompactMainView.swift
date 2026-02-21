//
//  RegularMainView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 10/02/2024.
//

import SwiftUI
import tdgCoreMain

struct CompactMainView: View {
    @Environment(UIStateManager.self) private var uiState

    var body: some View {
        @Bindable var uiState = uiState
        return NavigationStack(path: $uiState.navigationPath) {
            LeftSideView().background(Color.background)
                .navigationDestination(for: CompactDestination.self) { destination in
                    switch destination {
                    case .search:
                        VStack(spacing: 0) {
                            SearchFieldView()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            SearchResultsView()
                        }
                        .background(Color.background)
                        .navigationTitle("Search")
                        .onDisappear {
                            // Sync search state when user swipes back
                            guard uiState.isSearching else { return }
                            uiState.isSearching = false
                            uiState.searchText = ""
                        }
                    }
                }
                .navigationDestination(for: TaskItem.self) { item in
                    TaskItemView(item: item)
                }
                .navigationDestination(for: TaskItemState.self) { state in
                    ListView(whichList: state)
                        .standardToolbar(include: !isLargeDevice)
                }
                .mainToolbar()
                .standardToolbar()
        }.frame(maxWidth: .infinity)

    }
}
//#Preview {
//    CompactMainView()
//        .environment(dummyViewModel())
//}
