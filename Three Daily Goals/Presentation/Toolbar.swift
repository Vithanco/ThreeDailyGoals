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
            model.addItem()
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
            model.showReviewDialog = true
        }
    }
    
    var body: some ToolbarContent {
        ToolbarItem {
            Button(action: undo) {
                Label("Undo", systemImage: imgUndo)
            }.disabled(!model.canUndo)
        }
        ToolbarItem {
            Button(action: redo) {
                Label("Redo", systemImage: imgRedo)
            }.disabled(!model.canRedo)
        }
        
        ToolbarItem {
            Button(action: review) {
                Label("Review", systemImage: imgMagnifyingGlass)
            }
        }
        ToolbarItem {
            Button(action: addItem) {
                Label("Add Item", systemImage: imgAddItem)
            }
        }
    }
}


struct TDGToolBarModifier: ViewModifier {
    @Bindable var model: TaskManagerViewModel
    
    func body(content: Content) -> some View {
        return content
            .toolbar {
                TDGToolBarContent(model: model)
            }
    }
}

extension View {
    func tdgToolbar(model: TaskManagerViewModel) -> some View {
        return self.modifier(TDGToolBarModifier(model: model))
    }
}
