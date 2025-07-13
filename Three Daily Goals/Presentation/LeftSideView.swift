//
//  LeftSideView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 07/01/2024.
//

import SwiftUI

struct LeftSideView: View {
    @Bindable var model: TaskManagerViewModel
    var body: some View {
        VStack {
            #if os(iOS)
                FullStreakView(model: model).frame(maxWidth: .infinity, alignment: .center)
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
            ListView(whichList: .priority, model: model)
                .padding(5)
            Spacer()
            VStack {
                LinkToList(whichList: .open, model: model)
                LinkToList(whichList: .pendingResponse, model: model)
                LinkToList(whichList: .closed, model: model)
                LinkToList(whichList: .dead, model: model)
            }
            .padding(5)
            .background(model.isProductionEnvironment ? Color.clear : Color.yellow)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LeftSideView(model: dummyViewModel())
}
