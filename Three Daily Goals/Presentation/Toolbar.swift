//
//  Toolbar.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 08/01/2024.
//

import Foundation
import SwiftUI

struct MainToolbarContent: ToolbarContent {
    let model: TaskManagerViewModel

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

struct StandardToolbarContent: ToolbarContent {
    let model: TaskManagerViewModel

    var body: some ToolbarContent {
        ToolbarItem {
            model.undoButton
        }
        ToolbarItem {
            model.redoButton
        }
        ToolbarItem {
            model.compassCheckButton
        }
        ToolbarItem {
            model.addNewItemButton
        }
    }
}

struct ItemToolbarContent: ToolbarContent {
    let model: TaskManagerViewModel
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
    @Bindable var model: TaskManagerViewModel
    let include: Bool

    func body(content: Content) -> some View {
        return
            content
            .toolbar {
                if include {
                    StandardToolbarContent(model: model)
                }
            }
    }
}

struct ItemToolbarModifier: ViewModifier {
    @Bindable var model: TaskManagerViewModel
    let item: TaskItem
    let include: Bool

    func body(content: Content) -> some View {
        return
            content
            .toolbar {
                if include {
                    ItemToolbarContent(model: model, item: item)
                }
            }
    }
}

struct MainToolbarModifier: ViewModifier {
    @Bindable var model: TaskManagerViewModel
    let include: Bool

    func body(content: Content) -> some View {
        return
            content
            .toolbar {
                if include {
                    MainToolbarContent(model: model)
                }
            }
    }
}

extension View {

    /// include parameter was necessary in order to prevent flooding of the same toolbar on all views when shown on an iPad
    func standardToolbar(model: TaskManagerViewModel, include: Bool = true) -> some View {
        return self.modifier(StandardToolbarModifier(model: model, include: include))
    }

    func itemToolbar(model: TaskManagerViewModel, item: TaskItem, include: Bool = true) -> some View {
        return self.modifier(ItemToolbarModifier(model: model, item: item, include: include))
    }

    func mainToolbar(model: TaskManagerViewModel, include: Bool = true) -> some View {
        return self.modifier(MainToolbarModifier(model: model, include: include))
    }

}
