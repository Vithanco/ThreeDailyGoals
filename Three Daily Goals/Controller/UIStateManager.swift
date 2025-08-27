//
//  UIStateManager.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 14/01/2025.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class UIStateManager: @preconcurrency ItemSelector {

    // MARK: - Navigation State

    /// Currently selected task item (for detail view)
    var selectedItem: TaskItem?

    /// Currently selected list type
    var whichList: TaskItemState = .open

    /// Whether to show the detail view (iOS navigation)
    var showItem: Bool = false

    // MARK: - Dialog States

    /// Show compass check dialog
    var showCompassCheckDialog: Bool = false

    /// Show settings/preferences dialog
    var showSettingsDialog: Bool = false

    /// Show new item name dialog
    var showNewItemNameDialog: Bool = false

    /// Show import dialog
    var showImportDialog: Bool = false

    /// Show export dialog
    var showExportDialog: Bool = false

    /// Show select during import dialog
    var showSelectDuringImportDialog: Bool = false

    // MARK: - Alert States

    /// Show missing compass check alert
    var showMissingCompassCheckAlert: Bool = false

    // MARK: - User Messages

    /// Show info message
    var showInfoMessage: Bool = false

    /// Info message text
    var infoMessage: String = "(invalid)"

    // MARK: - Selection State

    /// Selected tags for filtering
    var selectedTags: [String] = []

    // MARK: - Import/Export State

    /// Choices for import conflict resolution
    var selectDuringImport: [Choice] = []

    // MARK: - Actions

    /// Finish any active dialog
    func finishDialog() {
        showInfoMessage = false
    }

    /// Select a task item and optionally its list
    func select(which: TaskItemState, item: TaskItem?) {
        withAnimation {
            whichList = which
            selectedItem = item
        }
    }

    /// Clear all dialog states
    func clearAllDialogs() {
        showCompassCheckDialog = false
        showSettingsDialog = false
        showNewItemNameDialog = false
        showImportDialog = false
        showExportDialog = false
        showSelectDuringImportDialog = false
        showMissingCompassCheckAlert = false
        showInfoMessage = false
    }

    /// Show an info message
    func showInfo(_ message: String) {
        infoMessage = message
        showInfoMessage = true
    }

    /// Show preferences dialog
    func showPreferences() {
        showSettingsDialog = true
    }

    /// Select a task item (platform-specific)
    func select(_ newItem: TaskItem) {
        #if os(macOS)
            select(which: newItem.state, item: newItem)
        #endif
        #if os(iOS)
            selectedItem = newItem
            showItem = true
        #endif
    }

    /// Show the new item dialog
    func addNewItem() {
        showNewItemNameDialog = true
    }

    // MARK: - Command Buttons

    /// Add new item button for app commands
    var addNewItemButton: some View {
        Button(action: { [self] in
            addNewItem()
        }) {
            Label("Add New Task", systemImage: imgAddItem)
                .help("Add a new task")
        }
    }

    /// Export button for app commands
    var exportButton: some View {
        Button(action: { [self] in
            showExportDialog = true
        }) {
            Label("Export Tasks", systemImage: imgExport)
                .help("Export tasks to JSON")
        }
    }

    /// Import button for app commands
    var importButton: some View {
        Button(action: { [self] in
            showImportDialog = true
        }) {
            Label("Import Tasks", systemImage: imgImport)
                .help("Import tasks from JSON")
        }
    }

    /// Stats dialog button for app commands
    var statsDialog: some View {
        Button(action: { [self] in
            showInfoMessage = true
        }) {
            Label("Show Statistics", systemImage: imgStats)
                .help("Show task statistics")
        }
    }
}

// MARK: - Convenience Initializers

extension UIStateManager {
    /// Create a UI state manager for testing
    static func testManager() -> UIStateManager {
        return UIStateManager()
    }
}
