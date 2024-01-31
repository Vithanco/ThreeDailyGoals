//
//  Preferences.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 28/01/2024.
//

import Foundation
import SwiftData
import SwiftUI
import os

fileprivate let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: Preferences.self)
)

typealias Preferences = SchemaLatest.Preferences


extension Preferences {
    var reviewTime: Date {
        set {
            reviewTimeHour = Calendar.current.component(.hour, from: newValue)
            reviewTimeMinutes = Calendar.current.component(.minute, from: newValue)
        }
        get {
            var date = Calendar.current.date(bySettingHour: reviewTimeHour, minute: reviewTimeMinutes, second: 0, of: Date())!
            if date < Date.now {
                date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
            }
            return date
        }
    }
    
    var accentColor: Color {
        get {
            if mainColorString == "" {
                return Color.accentColor
            }
            return Color(hex: mainColorString)
        }
        set {
            if let string = newValue.toHex {
                mainColorString = string
            } else {
                mainColorString = ""
            }
            
        }
    }
    
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
