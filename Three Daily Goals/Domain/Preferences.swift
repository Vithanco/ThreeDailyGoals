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
    category: String(describing: CloudPreferences.self)
)


let cloudDateFormatter : DateFormatter = {
    let result = DateFormatter()
    result.dateStyle = .medium
    result.timeStyle = .short
    return result
}()

enum CloudKey : String {
    case daysOfReview
    case reviewTimeHour
    case reviewTimeMinute
    case accentColorString
    case expiryAfter
    case lastReviewString
    case priority1
    case priority2
    case priority3
    case priority4
    case priority5

//    case allowedDaysOfSlack
//    case useCalendar
//    case makePriorityNumberOfDaysBeforeDue
//    case usePrioritisation
}

protocol KeyValueStorage {
    func int(forKey aKey: CloudKey) -> Int
    func set(_ value: Int, forKey aKey: CloudKey)
    
    func string(forKey aKey: CloudKey) -> String?
    func set(_ aString: String?, forKey aKey: CloudKey)
}

extension KeyValueStorage {
    func string(forKey aKey: CloudKey, defaultValue: String) -> String{
        return string(forKey: aKey) ?? defaultValue
    }
}

extension NSUbiquitousKeyValueStore : KeyValueStorage {
    
    func int(forKey aKey: CloudKey) -> Int {
        return Int(longLong(forKey: aKey.rawValue))
    }
    func set(_ value: Int, forKey aKey: CloudKey) {
        set(Int64(value), forKey: aKey.rawValue)
    }
    
    func string(forKey aKey: CloudKey) -> String? {
        return string (forKey: aKey.rawValue)
    }

    func set(_ aString: String?, forKey aKey: CloudKey)  {
        set(aString, forKey: aKey.rawValue)
    }
}

struct CloudPreferences {
    var store : KeyValueStorage
    
    init(store: KeyValueStorage) {
        self.store = store
    }
    
    init(testData: Bool){
        if testData {
            self.init(store: TestPreferences())
        } else {
            self.init(store: NSUbiquitousKeyValueStore.default)
        }
        
        // initiate the store with a proper time
        if store.string(forKey: .lastReviewString) == nil {
            store.set(18, forKey: .reviewTimeHour)
            store.set(00, forKey: .reviewTimeMinute)
        }
    }
}

extension CloudPreferences {
    var daysOfReview: Int {
        get {
            return self.store.int(forKey: .daysOfReview)
        }
        set {
            store.set(newValue,forKey: .daysOfReview)
        }
    }

    var nextReviewTime : Date {
        var result = reviewTime
        if result < Date.now {
            result = addADay(result)
        }
        return result
    }
        
    var didReviewToday : Bool {
        return lastReview.isToday
    }
    
    var reviewTime: Date {
        get {
//            the timing logic needs serious improvement - and some good test cases
            let reviewTimeHour = self.store.int(forKey: .reviewTimeHour)
            let reviewTimeMinute = self.store.int(forKey: .reviewTimeMinute)
            let date = Calendar.current.date(bySettingHour: reviewTimeHour, minute: reviewTimeMinute, second: 0, of: Date())!
            return date
        }
        set {
            store.set( Calendar.current.component(.hour, from: newValue), forKey: .reviewTimeHour)
            store.set(Calendar.current.component(.minute, from: newValue), forKey: .reviewTimeMinute)
        }
    }
    
    var reviewTimeComponents: DateComponents {
        return DateComponents(calendar: Calendar.current, hour:  self.store.int(forKey: .reviewTimeHour), minute: self.store.int(forKey: .reviewTimeMinute))
    }
                              
    var accentColor: Color {
        get {
            if let mainColorString = store.self.string(forKey: .accentColorString) {
                return Color(hex: mainColorString)
            }
            return Color.accentColor
        }
        set {
            if let string = newValue.toHex {
                store.set( string,forKey: .accentColorString)
            } else {
                store.set(nil, forKey: .accentColorString)
            }
            
        }
    }
    
    mutating func resetAccentColor(){
        store.set(nil, forKey: .accentColorString)
    }
    
    var expiryAfter: Int {
        get {
            let result = self.store.int(forKey: .expiryAfter)
            if result > 9 {  // default is 0, and that is an issue!
                store.set(30,forKey: .expiryAfter)
                return result
            }
            return 30
        }
        set {
            store.set(newValue,forKey: .expiryAfter)
        }
    }
    
    var expiryAfterString: String {
        return expiryAfter.description
    }
    
    var lastReview : Date {
        get {
            if let dateAsString = store.string(forKey: .lastReviewString), let result = cloudDateFormatter.date(from: dateAsString){
                return result
            }
            store.set(cloudDateFormatter.string(from: Date.now), forKey: .lastReviewString)
            return Date.now
        }
        set {
            store.set(cloudDateFormatter.string(from: newValue), forKey: .lastReviewString)
        }
    }

    
    fileprivate func nrToCloudKey(nr: Int) -> CloudKey {
        switch nr {
            case 1: return .priority1
            case 2: return .priority2
            case 3: return .priority3
            case 4: return .priority4
            case 5: return .priority5
            default: return .priority1
        }
    }
    func getPriority(nr:Int) -> String {
        return store.string(forKey: nrToCloudKey(nr: nr)) ?? ""
    }
    func setPriority(nr: Int, value: String) {
            store.set(value, forKey: nrToCloudKey(nr: nr))
    }
    
}


class TestPreferences : KeyValueStorage{
    
    var inner = NSUbiquitousKeyValueStore.default
    
    func int(forKey aKey: CloudKey) -> Int {
        let result = Int(inner.longLong(forKey: "test_" + aKey.rawValue))
        debugPrint("reading \(result) for test_\(aKey.rawValue)")
        return result
    }
    
    func set(_ value: Int, forKey aKey: CloudKey) {
        debugPrint("setting test_\(aKey.rawValue) to \(value)")
        inner.set(Int64(value), forKey: "test_" + aKey.rawValue)
    }
    
    func string(forKey aKey: CloudKey) -> String? {
        return inner.string (forKey: "test_" + aKey.rawValue)
    }
    
    func set(_ aString: String?, forKey aKey: CloudKey)  {
        inner.set(aString, forKey: "test_" + aKey.rawValue)
    }
}


func dummyPreferences() -> CloudPreferences {
    let store = TestPreferences()
    var result = CloudPreferences(store: store)
    result.daysOfReview = 42
    store.set(18, forKey: .reviewTimeHour)
    store.set(00, forKey: .reviewTimeMinute)
    return result
}
