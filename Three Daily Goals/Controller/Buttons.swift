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
            Label("Kill", systemImage: TaskItemState.closed.imageName).help("Move the task to the Graveyard")
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

    var  exportButton:  some View {
        Button("Export Tasks") {
            //                            #if os(iOS)
            //                            let fileManager = FileManager.default
            //                                    let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true) as [String]
            //                                    let filePath = "\(cachePath[0])/CloudKit"
            //                                    do {
            //                                        let contents = try fileManager.contentsOfDirectory(atPath: filePath)
            //                                        for file in contents {
            //                                            try fileManager.removeItem(atPath: "\(filePath)/\(file)")
            //                                            print("Deleted: \(filePath)/\(file)") //Optional
            //                                        }
            //                                    } catch {
            //                                        print("Errors!")
            //                                    }
            //                            #endif
            let fetchDescriptor = FetchDescriptor<TaskItem>()
            
            do {
                let items = try self.modelContext.fetch(fetchDescriptor)
                
                // Create an instance of JSONEncoder
                let encoder = JSONEncoder()
                // Convert your array into JSON data
                let data = try encoder.encode(items)
                // Specify the file path and name
                let url = getDocumentsDirectory().appendingPathComponent("taskItems.json")
                // Write the data to the file
                try data.write(to: url)
                self.fileUrl = "The file was saved to \(url)"
                self.showFileName = true
            } catch {
                self.fileUrl = "The file couldn't be saved because: \(error)"
                self.showFileName = true
            }
        }.keyboardShortcut("S", modifiers: [.command])
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
    
}

    

