//
//  Toolbar.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI

struct StandardToolbarContent: ToolbarContent {
    @Environment(TaskManagerViewModel.self) private var model

    var body: some ToolbarContent {
        ToolbarItem {
            model.preferencesButton
        }
        ToolbarItem {
            model.exportButton
        }
        ToolbarItem {
            model.importButton
        }
        ToolbarItem {
            model.statsDialog
        }
    }
}

struct MainToolbarContent: ToolbarContent {
    @Environment(TaskManagerViewModel.self) private var model

    var body: some ToolbarContent {
        ToolbarItem {
            model.undoButton
        }
        ToolbarItem {
            model.redoButton
        }
        ToolbarItem(placement: .principal) {
            model.compassCheckButton
        }
        ToolbarItem(placement: .principal) {
            model.addNewItemButton
        }
    }
}

struct ItemToolbarContent: ToolbarContent {
    @Environment(TaskManagerViewModel.self) private var model
    let item: TaskItem

    var body: some ToolbarContent {
        #if os(iOS)
            ToolbarItem {
                model.undoButton
            }
            ToolbarItem {
                model.redoButton
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
