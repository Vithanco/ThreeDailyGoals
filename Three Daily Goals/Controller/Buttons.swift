//
//  Buttons.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 14/02/2024.
//

import Foundation
import SwiftUI
import SwiftData
import CloudKit


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
        Button(action: {
            self.jsonExportDoc = JSONWriteOnlyDoc(content: self.items)
            self.showExportDialog = true
        }, label: {
            Label("Export Tasks", systemImage: "square.and.arrow.up.on.square.fill")
        }).keyboardShortcut("S", modifiers: [.command])
    }
    
    var importButton: some View {
        Button(action: {
            self.showImportDialog = true
        }, label: {
            Label("Import Tasks", systemImage: "square.and.arrow.down.on.square.fill")
        })
    }
    
    var statsDialog: some View {
        Button(action: {
            var msg = ""
            for s in TaskItemState.allCases {
                msg += "\n\(s.description.capitalized): \(self.lists[s]!.count)"
            }
            msg += "\nTotal: \(self.items.count)\nProduction-DB: \(CKContainer.isProductionEnvironment)"
            self.infoMessage = msg
            self.showInfoMessage = true
        }, label: {
            Label("Task Statistic", systemImage: "chart.bar.fill")
        })
    }
}
