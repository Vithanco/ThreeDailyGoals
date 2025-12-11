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
                .navigationDestination(for: TaskItem.self) { item in
                    TaskItemView(item: item)
                }
                .navigationDestination(for: TaskItemState.self) { state in
                    ListView(whichList: state)
                        .standardToolbar(include: !isLargeDevice)
                }
                .mainToolbar()
                .toolbar {
                    ToolbarItem {
                        uiState.addNewItemButton
                    }
                }
                .standardToolbar(include: isLargeDevice)
        }.frame(maxWidth: /*@START_MENU_TOKEN@*/ .infinity /*@END_MENU_TOKEN@*/)

    }
}
//#Preview {
//    CompactMainView()
//        .environment(dummyViewModel())
//}
