//
//  Toolbar.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI

struct StandardToolbarContent: ToolbarContent {
    @Environment(TaskManagerViewModel.self) private var model
    @Environment(UIStateManager.self) private var uiState

    var body: some ToolbarContent {
        ToolbarItem {
            Button(action: { uiState.showPreferences() }) {
                Label("Preferences", systemImage: "gear").accessibilityIdentifier("showPreferencesButton").help("Show Preferences Dialog")
            }
        }
        ToolbarItem {
            uiState.exportButton
        }
        ToolbarItem {
            uiState.importButton
        }
        ToolbarItem {
            uiState.statsDialog
        }
    }
}

struct MainToolbarContent: ToolbarContent {
    @Environment(TaskManagerViewModel.self) private var model
    @Environment(DataManager.self) private var dataManager
    @Environment(UIStateManager.self) private var uiState
    @Environment(CompassCheckManager.self) private var compassCheckManager

    var body: some ToolbarContent {
        ToolbarItem {
            dataManager.undoButton
        }
        ToolbarItem {
            dataManager.redoButton
        }
        ToolbarItem(placement: .principal) {
            compassCheckManager.compassCheckButton
        }
        ToolbarItem(placement: .principal) {
            uiState.addNewItemButton
        }
    }
}

struct ItemToolbarContent: ToolbarContent {
    @Environment(TaskManagerViewModel.self) private var model
    @Environment(DataManager.self) private var dataManager
    let item: TaskItem

    var body: some ToolbarContent {
        #if os(iOS)
            ToolbarItem {
                dataManager.undoButton
            }
            ToolbarItem {
                dataManager.redoButton
            }
        #endif
        ToolbarItem {
            model.toggleButton(item: item)
        }
        if item.canBeClosed {
            ToolbarItem {
                model.closeButton(item: item)
            }
        }
        if item.canBeMovedToOpen {
            ToolbarItem {
                model.openButton(item: item)
            }
        }
        if item.canBeMovedToPendingResponse {
            ToolbarItem {
                model.waitForResponseButton(item: item)
            }
        }
        if item.canBeTouched {
            ToolbarItem {
                model.touchButton(item: item)
            }
        }
    }
}

struct StandardToolbarModifier: ViewModifier {
    let include: Bool

    func body(content: Content) -> some View {
        return
            content
            .toolbar {
                if include {
                    StandardToolbarContent()
                }
            }
    }
}

struct ItemToolbarModifier: ViewModifier {
    let item: TaskItem
    let include: Bool

    func body(content: Content) -> some View {
        return
            content
            .toolbar {
                if include {
                    ItemToolbarContent(item: item)
                }
            }
    }
}

struct MainToolbarModifier: ViewModifier {
    let include: Bool

    func body(content: Content) -> some View {
        return
            content
            .toolbar {
                if include {
                    MainToolbarContent()
                }
            }
    }
}

extension View {

    /// include parameter was necessary in order to prevent flooding of the same toolbar on all views when shown on an iPad
    func standardToolbar(include: Bool = true) -> some View {
        return self.modifier(StandardToolbarModifier(include: include))
    }

    func itemToolbar(item: TaskItem, include: Bool = true) -> some View {
        return self.modifier(ItemToolbarModifier(item: item, include: include))
    }

    func mainToolbar(include: Bool = true) -> some View {
        return self.modifier(MainToolbarModifier(include: include))
    }

}
