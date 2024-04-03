//
//  Toolbar.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 08/01/2024.
//

import Foundation
import SwiftUI

struct TDGToolBarContent: ToolbarContent {
    @Bindable var model: TaskManagerViewModel
    
    private func addItem() {
        let _ = withAnimation {
            model.addAndSelect()
        }
    }
    
    private func undo() {
        withAnimation {
            model.undo()
        }
    }
    
    private func redo() {
        withAnimation {
            model.redo()
        }
    }
    
    private func review() {
        withAnimation {
            model.reviewNow()
        }
    }
    
    private func showPreferences() {
        withAnimation{
            model.showSettingsDialog = true
        }
    }
    
    var body: some ToolbarContent {
        ToolbarItem {
            model.undoButton
        }
        ToolbarItem {
            model.redoButton
        }
        
        ToolbarItem {
            Button(action: review) {
                Label("Review", systemImage: imgReview).accessibilityIdentifier("reviewButton").help("Start the daily review now.")
            }
        }
        ToolbarItem {
            Button(action: addItem) {
                Label("Add Task", systemImage: imgAddItem).help("Add new task to list of open tasks. ").accessibilityIdentifier("addTaskButton")
            }
        }
        #if os(iOS) // see Three_Daily_GoalsApp for Mac way
        ToolbarItem {
            Button(action: showPreferences) {
                Label("Preferences", systemImage: imgPreferences).accessibilityIdentifier("showPreferencesButton").help("Show Preferences Dialog")
            }
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
        #endif
    }
}


struct TDGToolBarModifier: ViewModifier {
    @Bindable var model: TaskManagerViewModel
    let include: Bool
    
    func body(content: Content) -> some View {
        return content
            .toolbar {
                if include {
                    TDGToolBarContent(model: model)
                }
            }
    }
}

extension View {
    
    /// include parameter was necessary in order to prevent flooding of the same toolbar on all views when shown on an iPad
    func tdgToolbar(model: TaskManagerViewModel, include: Bool) -> some View {
        return self.modifier(TDGToolBarModifier(model: model, include: include))
    }
}
