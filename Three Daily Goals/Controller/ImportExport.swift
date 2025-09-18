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
import tdgCoreMain

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: "ImportExport")
)

public struct SelectVersions: View {
    let choices: [Choice]
    @State var index: Int = 0
    @Environment(DataManager.self) private var dataManager
    @Environment(UIStateManager.self) private var uiState
    @Environment(CloudPreferences.self) private var preferences

    func nextChoice() {
        index += 1
        if index == choices.count {
            done()
        }
    }

    func done() {
        uiState.showSelectDuringImportDialog = false
    }

    func alwaysUseNew() {
        for i in index...choices.count - 1 {
            dataManager.remove(task: choices[i].existing)
            dataManager.addItem(item: choices[i].new)
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
    public var body: some View {
        VStack {
            Text("Remaining Choices: \(remaining)")
            HStack {
                VStack {
                    Text("Existing Version")
                    InnerTaskItemView(
                        item: currentChoice.existing, allTags: [],
                        showAttachmentImport: false)
                    Button("Use existing") {
                        nextChoice()
                    }
                    Button("Always use Existing", role: .destructive) {
                        // nothing to be done!
                        done()
                    }
                }
                VStack {
                    Text("Imported Version")
                    InnerTaskItemView(
                        item: currentChoice.new, allTags: [],
                        showAttachmentImport: false)
                    Button("Use new") {
                        dataManager.remove(task: currentChoice.existing)
                        dataManager.addItem(item: currentChoice.new)
                        nextChoice()
                    }
                    Button("Always use new", role: .destructive) {
                        alwaysUseNew()
                    }
                }
            }
        }.frame(minWidth: 600, idealWidth: 1000, minHeight: 600, idealHeight: 1000)
    }
}
