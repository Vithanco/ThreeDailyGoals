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
                .navigationDestination(for: TaskItem.self) { item in
                    TaskItemView(item: item)
                }
                .navigationDestination(for: TaskItemState.self) { state in
                    ListView(whichList: state)
                        .standardToolbar(include: !isLargeDevice)
                }
                .mainToolbar()
                .standardToolbar()
        }.frame(maxWidth: /*@START_MENU_TOKEN@*/ .infinity /*@END_MENU_TOKEN@*/)

    }
}
//#Preview {
//    CompactMainView()
//        .environment(dummyViewModel())
//}
