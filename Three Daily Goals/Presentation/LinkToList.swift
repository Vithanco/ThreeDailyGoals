//
//  LinkToList.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftData
import SwiftUI
import tdgCoreMain

private struct ListLabel: View {
    let whichList: TaskItemState
    @Environment(DataManager.self) private var dataManager
    @Environment(CloudPreferences.self) private var preferences
    @Environment(\.colorScheme) private var colorScheme
    @Environment(UIStateManager.self) private var uiState

    init(whichList: TaskItemState) {
        self.whichList = whichList
    }
    
    @Query private var allTasks: [TaskItem]
    
    private var tasks: [TaskItem] {
        allTasks.filter { $0.state == whichList }
    }

    var name: Text {
        return whichList.section.asText
    }

    var count: Text {
        return Text(tasks.count.description)
    }
    
    // Enhanced list icons using the new semantic icons
    private var listIcon: String {
        return whichList.imageName
    }
    
    // List-specific colors
    private var listColor: Color {
        return whichList.color
    }

    // Check if this list is currently selected
    private var isSelected: Bool {
        return uiState.whichList == whichList
    }

    private var verticalPadding: CGFloat {
        return isLargeDevice ? 12.0 : 4.0
    }

    // Stronger background and shadow for standout effect
    private var cardBackground: LinearGradient {
        let base = colorScheme == .dark ? Color.neutral800 : Color.neutral50
        let highlight = colorScheme == .dark ? Color.neutral700 : Color.white.opacity(0.7)
        return LinearGradient(
            gradient: Gradient(colors: [highlight, base]),
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    private var cardShadow: Color {
        colorScheme == .dark ? .black.opacity(0.23) : .black.opacity(0.18)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Accent bar for visual pop
            RoundedRectangle(cornerRadius: 5)
                .fill(listColor)
                .frame(width: 5)
                .shadow(color: listColor.opacity(0.2), radius: isSelected ? 5 : 3, x: 0, y: 0)
                .padding(.vertical, 6)
                .padding(.trailing, 12)

            HStack(spacing: 12) {
                // Single semantic list icon with color
                Image(systemName: listIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(listColor)
                    .frame(width: 28, height: 28)
                
                // List name only (removed duplicate count)
                name
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Enhanced count badge
                if whichList.showCount && tasks.count > 0 {
                    Text(tasks.count.description)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(listColor)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, verticalPadding)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBackground)
                .shadow(
                    color: cardShadow,
                    radius: isSelected ? 8 : 6,
                    x: 0,
                    y: 3
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isSelected ? listColor : (colorScheme == .dark ? Color.neutral700 : Color.neutral200),
                    lineWidth: isSelected ? 3 : 1.2
                )
        )
        .scaleEffect(isSelected ? 1.035 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
        .accessibilityIdentifier(whichList.getLinkedListAccessibilityIdentifier)
        .dropDestination(for: String.self) { items, location in
            for item in items.compactMap({ dataManager.findTask(withUuidString: $0) }) {
                dataManager.move(task: item, to: whichList)
            }
            return true
        }
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
                }
            }
        }
    }
}

#Preview {
    let appComp = setupApp(isTesting: true)
    LinkToList(whichList: .open)
            .environment(appComp.uiState)
            .environment(appComp.dataManager)
            .environment(appComp.preferences)
}
