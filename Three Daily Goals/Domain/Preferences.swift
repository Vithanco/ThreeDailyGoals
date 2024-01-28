//
//  Preferences.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 28/01/2024.
//

import Foundation
import SwiftData
import os

fileprivate let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: Preferences.self)
)

typealias Preferences = SchemaLatest.Preferences


extension Preferences {
   
}



func loadPreferences(modelContext: Storage) -> Preferences {
    let fetchDescriptor = FetchDescriptor<Preferences>()
    
    do {
        let preferences = try modelContext.fetch(fetchDescriptor)
        if preferences.count > 1 {
            logger.error("more than one preferences! Found \(preferences.count) entries! Why?")
            for d in preferences {
                modelContext.delete(d)
            }
        }
        if let result = preferences.first {
            return result
        }
    }
    catch {
        logger.warning("no data available? - creating default preferences")
    }
    let new = Preferences()
    modelContext.insert(new)
    return new
}
