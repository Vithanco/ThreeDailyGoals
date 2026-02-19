//
//  UIStateManager.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 14/01/2025.
//

import Foundation
import SwiftUI
import TipKit
import tdgCoreMain
import tdgCoreWidget

@MainActor
@Observable
public final class UIStateManager: ItemSelector, DataIssueReporter {

    // MARK: - Navigation State

    /// Currently selected task item (for detail view)
    var selectedItem: TaskItem?

    var newItemProducer: NewItemProducer? = nil

    /// Currently selected list type
    var whichList: TaskItemState = .open

    /// Whether to show the detail view (iOS navigation)
    var showItem: Bool = false

    // MARK: - Dialog States

    /// Show compass check dialog
    var showCompassCheckDialog: Bool = false

    /// Show settings/preferences dialog
    var showSettingsDialog: Bool = false

    /// Show import dialog
    var showImportDialog: Bool = false

    /// Show export dialog
    var showExportDialog: Bool = false

    /// Show select during import dialog
    var showSelectDuringImportDialog: Bool = false

    // MARK: - Alert States

    /// Show missing compass check alert
    var showMissingCompassCheckAlert: Bool = false

    /// Show database error alert
    var showDatabaseErrorAlert: Bool = false

    /// Current database error
    var databaseError: DatabaseError?

    // MARK: - User Messages

    /// Show info message
    var showInfoMessage: Bool = false

    /// Info message text
    var infoMessage: String = "(invalid)"

    // MARK: - Search State

    /// Whether the search field is active
    var isSearching: Bool = false

    /// Current search query text
    var searchText: String = ""

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
    @MainActor
    func select(which: TaskItemState, item: TaskItem?) {
        Task { @MainActor in
            withAnimation {
                if which != .priority {
                    whichList = which
                }
                selectedItem = item
            }
        }
    }

    /// Clear all dialog states
    func clearAllDialogs() {
        showCompassCheckDialog = false
        showSettingsDialog = false
        showImportDialog = false
        showExportDialog = false
        showSelectDuringImportDialog = false
        showMissingCompassCheckAlert = false
        showDatabaseErrorAlert = false
        showInfoMessage = false
    }

    /// Show an info message
    func showInfo(_ message: String) {
        infoMessage = message
        showInfoMessage = true
    }

    /// Show a database error
    func showDatabaseError(_ error: DatabaseError) {
        databaseError = error
        showDatabaseErrorAlert = true
    }

    /// Report a database error (DataIssueReporter protocol)
    public func reportDatabaseError(_ error: DatabaseError) {
        showDatabaseError(error)
    }

    /// Report data loss to the user
    public func reportDataLoss(_ message: String, details: String?) {
        let fullMessage = details != nil ? "\(message)\n\nDetails: \(details!)" : message
        showInfo("⚠️ Data Loss Warning\n\n\(fullMessage)")
    }

    /// Report migration issues to the user
    public func reportMigrationIssue(_ message: String, details: String?) {
        let fullMessage = details != nil ? "\(message)\n\nDetails: \(details!)" : message
        showInfo("⚠️ Migration Issue\n\n\(fullMessage)")
    }

    /// Start searching
    func startSearch() {
        isSearching = true
        selectedItem = nil
    }

    /// Stop searching and clear query
    func stopSearch() {
        isSearching = false
        searchText = ""
    }

    /// Show preferences dialog
    func showPreferences() {
        showSettingsDialog = true
    }

    /// Select a task item (platform-specific)
    @MainActor
    public func select(_ newItem: TaskItem) {
        if newItem == selectedItem {
            return
        }
        if let oldItem = selectedItem {
            // Check if oldItem is still in the context (not deleted)
            // If modelContext is nil, the item has been deleted
            if oldItem.modelContext != nil && oldItem.isUnchanged {
                newItemProducer?.removeItem(oldItem)
            }
            selectedItem = nil
        }
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
        if let newItem = newItemProducer?.produceNewItem() {
            select(newItem)
        }
    }

    // MARK: - Command Buttons

    /// Add new item button for app commands
    var addNewItemButton: some View {
        Button(action: { [self] in
            addNewItem()
        }) {
            Label("Add New Task", systemImage: imgAddItem)
                .foregroundStyle(TaskItemState.open.color)
                .help("Add a new task")
        }
        .accessibilityIdentifier("addTaskButton")
        .popoverTip(AddFirstGoalTip())
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

}
