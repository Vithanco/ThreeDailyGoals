//
//  LinkToList.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftData
import SwiftUI

private struct ListLabel: View {
    let whichList: TaskItemState
    @Environment(DataManager.self) private var dataManager
    @Environment(CloudPreferences.self) private var preferences

    var name: Text {
        return whichList.section.asText
    }

    var count: Text {
        return Text(dataManager.list(which: whichList).count.description)
    }

    var body: some View {
        HStack {
            name
            Spacer()
            if whichList.showCount {
                count
            }
        }.accessibilityIdentifier(whichList.getLinkedListAccessibilityIdentifier)
            .dropDestination(for: String.self) {
                items, location in
                for item in items.compactMap({ dataManager.findTask(withUuidString: $0) }) {
                    dataManager.move(task: item, to: whichList)
                }
                return true
            }
            .foregroundStyle(preferences.accentColor)
            .frame(maxWidth: .infinity)
    }
}

struct LinkToList: View {
    @State var whichList: TaskItemState
    @Environment(UIStateManager.self) private var uiState
    @Environment(DataManager.self) private var dataManager
    @Environment(CloudPreferences.self) private var preferences

    var body: some View {
        SingleView {
            if isLargeDevice {
                ListLabel(whichList: whichList)
                    .onTapGesture {
                        uiState.select(which: whichList, item: dataManager.list(which: whichList).first)
                    }
            } else {
                NavigationLink {
                    ListView(whichList: whichList)
                        .standardToolbar(include: !isLargeDevice)
                } label: {
                    ListLabel(whichList: whichList)
                        .foregroundStyle(preferences.accentColor)
                }
            }
        }
    }
}

#Preview {
    LinkToList(whichList: .open)
        .environment(UIStateManager.testManager())
        .environment(DataManager.testManager())
        .environment(dummyPreferences())
}
