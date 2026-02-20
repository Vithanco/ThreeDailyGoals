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
        return NavigationStack {
            LeftSideView().background(Color.background)
                .navigationDestination(isPresented: $uiState.showItem) {
                    if let item = uiState.selectedItem {
                        TaskItemView(item: item)
                    }
                }
                .navigationDestination(isPresented: $uiState.isSearching) {
                    VStack(spacing: 0) {
                        SearchFieldView()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        SearchResultsView()
                    }
                    .background(Color.background)
                    .navigationTitle("Search")
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
