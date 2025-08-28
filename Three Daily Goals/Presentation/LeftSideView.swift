//
//  LeftSideView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI

struct LeftSideView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(CloudKitManager.self) private var cloudKitManager

    var body: some View {
        VStack(spacing: 0) {
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
                        for item in items.compactMap({ dataManager.findTask(withUuidString: $0) }) {
                            dataManager.moveWithPriorityTracking(task: item, to: .open)
                        }
                        return true
                    }
                }
            #endif
            
            // Priority list (main content area)
            ListView(whichList: .priority)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            Spacer()
            
            // List selector section
            VStack(spacing: 8) {
                // Section header
                HStack {
                    Text("Lists")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // List items
                VStack(spacing: 6) {
                    LinkToList(whichList: .open)
                    LinkToList(whichList: .pendingResponse)
                    LinkToList(whichList: .closed)
                    LinkToList(whichList: .dead)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(cloudKitManager.isProductionEnvironment ? Color.clear : Color.yellow.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LeftSideView()
        .environment(dummyViewModel())
}
