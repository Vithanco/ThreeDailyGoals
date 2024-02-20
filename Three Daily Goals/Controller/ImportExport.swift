//
//  ImportExport.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/02/2024.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

import os

fileprivate let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: "TaskManagerViewModel.Buttons")
)

extension TaskManagerViewModel {
    func exportTasks(url: URL){
        do {
            // Create an instance of JSONEncoder
            let encoder = JSONEncoder()
            // Convert your array into JSON data
            let data = try encoder.encode(items)

            // Write the data to the file
            try data.write(to: url)
            self.infoMessage = "The tasks were exported and saved as JSON to \(url)"
        } catch {
            self.infoMessage = "The tasks weren't exported because: \(error)"
        }
        logger.info("\(self.infoMessage)")
        self.showInfoMessage = true
    }
    
    func importTasks(url: URL) {
        // url contains the URL of the chosen file.
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode([TaskItem].self, from: data)
            beginUndoGrouping()
            for item in jsonData {
                self.removeItem(withID: item.id)
                self.addItem(item:item)
            }
            endUndoGrouping()
            self.infoMessage = "\(jsonData.count) tasks were imported."
        } catch {
            self.infoMessage  = "The tasks weren't imported because :\(error)"
        }
        logger.info("\(self.infoMessage)")
        self.showInfoMessage = true
    }
}
