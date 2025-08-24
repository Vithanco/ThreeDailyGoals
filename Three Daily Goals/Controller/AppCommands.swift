import Foundation
import SwiftUI

/// Command buttons for the app menu
@MainActor
struct AppCommands {
    let appComponents: AppComponents
    
    init(appComponents: AppComponents) {
        self.appComponents = appComponents
    }
    
    var undoButton: some View {
        Button(action: {
            withAnimation {
                appComponents.dataManager.undo()
                appComponents.dataManager.callFetch()
            }
        }) {
            Label("Undo", systemImage: "arrow.uturn.backward").accessibilityIdentifier("undoButton").help(
                "undo an action")
        }.disabled(!appComponents.dataManager.canUndo)
            .keyboardShortcut("z", modifiers: [.command])
    }
    
    var redoButton: some View {
        Button(action: {
            withAnimation {
                appComponents.dataManager.redo()
                appComponents.dataManager.callFetch()
            }
        }) {
            Label("Redo", systemImage: "arrow.uturn.forward").accessibilityIdentifier("redoButton").help(
                "redo an action")
        }.disabled(!appComponents.dataManager.canRedo)
            .keyboardShortcut("Z", modifiers: [.command, .shift])
    }
    
    var addNewItemButton: some View {
        Button(action: {
            appComponents.uiState.addNewItem()
        }) {
            Label("Add New Task", systemImage: "plus").help("Add a new task")
        }
    }
    
    var exportButton: some View {
        Button(action: {
            appComponents.uiState.showExportDialog = true
        }) {
            Label("Export Tasks", systemImage: "square.and.arrow.up").help("Export tasks to JSON")
        }
    }
    
    var importButton: some View {
        Button(action: {
            appComponents.uiState.showImportDialog = true
        }) {
            Label("Import Tasks", systemImage: "square.and.arrow.down").help("Import tasks from JSON")
        }
    }
    
    var statsDialog: some View {
        Button(action: {
            appComponents.uiState.showInfoMessage = true
        }) {
            Label("Show Statistics", systemImage: "chart.bar").help("Show task statistics")
        }
    }
    
    var compassCheckButton: some View {
        Button(action: {
            appComponents.compassCheckManager.startCompassCheckNow()
        }) {
            Label("Compass Check", systemImage: "location.north").help("Start compass check")
        }
    }
}
