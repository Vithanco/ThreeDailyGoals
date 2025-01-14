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

private let logger = Logger(
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
    
    
        /// url contains the URL of the chosen file.
    func importTasks(url: URL) {
        var choices = [Choice]()
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode([TaskItem].self, from: data)
            beginUndoGrouping()
            for item in jsonData {
                if let existing = findTask(withID: item.id) {
                    if existing != item {
                        choices.append(Choice(existing: existing, new: item))
                    }
                } else {
                    addItem(item: item)
                }
            }
            self.selectDuringImport = choices
            showSelectDuringImportDialog = true
            self.infoMessage = "\(jsonData.count) tasks were imported."
        }catch {
            self.infoMessage  = "The tasks weren't imported because :\(error)"
        }
        
        
        endUndoGrouping()
        logger.info("\(self.infoMessage)")
        self.showInfoMessage = true
    }
}


struct SelectVersions: View {
    let choices: [Choice]
    @State var index: Int = 0
    @Bindable var model: TaskManagerViewModel
    
    func nextChoice() {
        index += 1
        if index == choices.count{
           done()
        }
    }
    
    func done() {
        model.showSelectDuringImportDialog = false
    }
    
    func alwaysUseNew(){
        for i in index ... choices.count - 1 {
            model.remove(item: choices[i].existing)
            model.addItem(item: choices[i].new)
        }
        done()
    }
    
    var currentChoice: Choice {
        if index >= choices.count {
            return choices[0]
        }
       return choices[index]
    }
    
    var remaining: Int {
        return choices.count - index
    }
    var body: some View {
        VStack{
            Text("Remaining Choices: \(remaining)")
            HStack{
                VStack{
                    Text("Existing Version")
                    InnerTaskItemView(accentColor: model.accentColor, item: currentChoice.existing, allTags: [], selectedTagStyle: model.selectedTagStyle, missingTagStyle: model.missingTagStyle)
                    Button("Use existing"){
                        nextChoice()
                    }
                    Button("Always use Existing", role: .destructive) {
                        // nothing to be done!
                        done()
                    }
                }
                VStack{
                    Text("Imported Version")
                    InnerTaskItemView(accentColor: model.accentColor, item: currentChoice.new, allTags: [], selectedTagStyle: model.selectedTagStyle, missingTagStyle: model.missingTagStyle)
                    Button("Use new"){
                        model.remove(item: currentChoice.existing)
                        model.addItem(item:currentChoice.new)
                        nextChoice()
                    }
                    Button("Always use new", role: .destructive) {
                        alwaysUseNew()
                    }
                }
            }
        }.frame(minWidth: 600, idealWidth: 1000, minHeight: 600,  idealHeight: 1000)
    }
}
