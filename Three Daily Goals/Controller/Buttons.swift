//
//  Buttons.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 14/02/2024.
//

import CloudKit
import Foundation
import SwiftData
import SwiftUI

extension TaskManagerViewModel {

    @MainActor
    func toggleButton(item: TaskItem) -> some View {
        return Button(action: {
            if item.state == .priority {
                self.move(task: item, to: .open)
            } else {
                self.move(task: item, to: .priority)
            }
        }) {
            Label("Toggle Priority", systemImage: item.state == .priority ?  TaskItemState.open.imageName : TaskItemState.priority.imageName    )
                .help("Add to/ remove from today's priorities")
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

    func waitForResponseButton(item: TaskItem) -> some View {
        return Button(action: {
            self.move(task: item, to: .pendingResponse)
        }) {
            Label("Pending a Response", systemImage: TaskItemState.pendingResponse.imageName).help(
                "Mark as Pending Response. That is the state for a task that you completed, but you are waiting for a response, acknowledgement or similar."
            )
        }.accessibilityIdentifier("openButton").disabled(!item.canBeMovedToOpen)
    }

    func touchButton(item: TaskItem) -> some View {
        return Button(action: {
            item.touch()
        }) {
            Label("Touch", systemImage: imgTouch).help("'Touch' the task - when you did something with it.")
        }.accessibilityIdentifier("touchButton")
    }

    func priorityButton(item: TaskItem) -> some View {
        return Button(action: {
            self.move(task: item, to: .priority)
        }) {
            Image(systemName: imgToday).frame(width: 8, height: 8).help("Make this task a priority for today")
        }.accessibilityIdentifier("prioritiseButton")
    }

    @MainActor
    func deleteButton(item: TaskItem) -> some View {
        return Button(
            role: .destructive,
            action: {
                self.delete(task: item)
            }
        ) {
            Label("Delete", systemImage: "trash").help("Delete this task for good.")
        }.accessibilityIdentifier("deleteButton")
    }

    var undoButton: some View {
        Button(action: undo) {
            Label("Undo", systemImage: imgUndo).accessibilityIdentifier("undoButton").help("undo an action")
        }.disabled(!canUndo)
            .keyboardShortcut("z", modifiers: [.command])
    }

    var redoButton: some View {
        Button(action: redo) {
            Label("Redo", systemImage: imgRedo).accessibilityIdentifier("redoButton").help("redo an action")
        }.disabled(!canRedo)
            .keyboardShortcut("Z", modifiers: [.command, .shift])
    }

    var exportButton: some View {
        Button(
            action: {
                self.jsonExportDoc = JSONWriteOnlyDoc(content: self.items)
                self.showExportDialog = true
            },
            label: {
                Label("Export Tasks", systemImage: "square.and.arrow.up.on.square.fill")
            }
        ).keyboardShortcut("S", modifiers: [.command])
    }

    var importButton: some View {
        Button(
            action: {
                self.showImportDialog = true
            },
            label: {
                Label("Import Tasks", systemImage: "square.and.arrow.down.on.square.fill")
            }
        )
    }

    var statsDialog: some View {
        Button(
            action: {
                var msg = ""
                for s in TaskItemState.allCases {
                    msg += "\n\(s.description.capitalized): \(self.lists[s]!.count)"
                }
                msg += "\nTotal: \(self.items.count)\nProduction-DB: \(self.isProductionEnvironment)"
                debugPrint(msg)
                self.infoMessage = msg
                self.showInfoMessage = true
            },
            label: {
                Label("Task Statistic", systemImage: "chart.bar.fill")
            }
        )
    }

    var addNewItemButton: some View {
        Button(action: addNewItem) {
            Label("Add Task", systemImage: imgAddItem).help("Add new task to list of open tasks").accessibilityIdentifier("addTaskButton")
        }
        .keyboardShortcut("n", modifiers: [.command])
    }

    var compassCheckButton: some View {
        Button(action: compassCheckNow) {
            Label("Compass Check", systemImage: imgCompassCheck)
                // .symbolRenderingMode(.palette)
                .foregroundStyle(.gray, preferences.accentColor)
                .accessibilityIdentifier("compassCheckButton").help("Start the Compass Check now")

        }
    }
}
