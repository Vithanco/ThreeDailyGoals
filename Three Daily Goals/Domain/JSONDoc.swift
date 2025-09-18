//
//  JSONDoc.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 20/02/2024.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import tdgCoreMain

// simple doc to save my JSON data
public struct JSONWriteOnlyDoc: FileDocument, @unchecked Sendable {
    public static var readableContentTypes: [UTType] { [.json] }

    private var content: [TaskItem]
    init(content: [TaskItem]) {
        self.content = content
    }

    // simple wrapper, w/o WriteConfiguration multi types or
    // existing file selected handling (it is up to you)
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        // Convert your array into JSON data
        let data = try encoder.encode(content)
        return FileWrapper(regularFileWithContents: data)
    }

    public init(configuration: ReadConfiguration) throws {
        assert(false)
        self.content = []
    }
}
