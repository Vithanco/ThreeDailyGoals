//
//  LeftSideView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI

struct LeftSideView: View {
    @Environment(TaskManagerViewModel.self) private var model

    var body: some View {
        VStack {
            #if os(iOS)
                FullStreakView().frame(maxWidth: .infinity, alignment: .center)
                    .standardToolbar(include: !isLargeDevice)
                if isLargeDevice {
                    HStack {
                        Spacer()
                        Circle().frame(width: 10).foregroundColor(.accentColor).help(
                            "Drop Target, as iOS has an issue. Will be hopefully removed with next version of iOS."
                        )
                        Spacer()
                    }
                    .dropDestination(for: String.self) {
                        items,
                        location in
                        for item in items.compactMap({ model.findTask(withUuidString: $0) }) {
                            model.move(task: item, to: .open)
                        }
                        return true
                    }
                }
            #endif
            ListView(whichList: .priority)
                .padding(5)
            Spacer()
            VStack {
                LinkToList(whichList: .open)
                LinkToList(whichList: .pendingResponse)
                LinkToList(whichList: .closed)
                LinkToList(whichList: .dead)
            }
            .padding(5)
            .background(model.isProductionEnvironment ? Color.clear : Color.yellow)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LeftSideView()
        .environment(dummyViewModel())
}
