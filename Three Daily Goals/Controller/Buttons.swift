//
//  Buttons.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 14/02/2024.
//

import Foundation
import SwiftUI
import SwiftData


extension TaskManagerViewModel {
    
    func toggleButton(item: TaskItem) -> some View {
        return Button(action:  {
            if item.state == .priority{
                self.move(task: item, to: .open)
            } else {
                self.move(task: item, to: .priority)
            }
        }) {
            Label("Toggle Priority", systemImage: TaskItemState.priority.imageName).help("Add to/ remove from today's priorities")
        }.accessibilityIdentifier("toggleButton")
    }
    
    func closeButton(item: TaskItem) -> some View {
        return Button(action: {
            self.move(task: item, to: .closed)
        }) {
            Label("Close", systemImage: TaskItemState.closed.imageName).help("Close the task")
        }.accessibilityIdentifier("closeButton").disabled(!item.canBeClosed)
    }
    
    func killButton(item: TaskItem) -> some View {
        return Button(action: {
            self.move(task: item, to: .dead)
        }) {
            Label("Kill", systemImage: TaskItemState.dead.imageName).help("Move the task to the Graveyard")
        }.accessibilityIdentifier("killButton").disabled(!item.canBeClosed)
    }
    
    func openButton(item: TaskItem) -> some View {
        return Button(action: {
            self.move(task: item, to: .open)
        }) {
            Label("Open", systemImage: TaskItemState.open.imageName).help("Open this task again")
        }.accessibilityIdentifier("openButton").disabled(!item.canBeMovedToOpen)
    }
    
    func touchButton(item: TaskItem) -> some View {
        return Button(action: {
            item.touch()
        }) {
            Label("Touch", systemImage: imgTouch).help("'Touch' the task - when you did something with it.")
        }.accessibilityIdentifier("touchButton")
    }
    
    func deleteButton(item: TaskItem) -> some View {
        return Button (role: .destructive, action: {
            self.delete(task: item)
        }) {
            Label("Delete", systemImage: "trash").help("Delete this task for good.")
        }.accessibilityIdentifier("deleteButton")
    }
    
    var undoButton: some View {
        return Button("Undo") {
            self.modelContext.undoManager?.undo()
        }
        .keyboardShortcut("z", modifiers: [.command])
    }

    var redoButton: some View {
        return Button("Redo") {
            self.modelContext.undoManager?.redo()
        }
        .keyboardShortcut("Z", modifiers: [.command, .shift])
    }
    
    var exportButton: some View {
        Button("Export Tasks") {
            self.jsonExportDoc = JSONWriteOnlyDoc(content: self.items)
            self.showExportDialog = true
        }.keyboardShortcut("S", modifiers: [.command])
    }
    
    var importButton: some View {
        Button("Import Tasks") {
            self.showImportDialog = true
        }
    }
}
