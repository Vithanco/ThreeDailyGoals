//
//  Preferences.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 28/01/2024.
//

import CloudKit
import Foundation
import SwiftData
import SwiftUI
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: CloudPreferences.self)
)

let cloudDateFormatter: DateFormatter = {
    let result = DateFormatter()
    result.dateStyle = .medium
    result.timeStyle = .short
    return result
}()

enum CloudKey: String, CaseIterable {
    case daysOfCompassCheck
    case longestStreak
    case currentCompassCheckIntervalStart
    case currentCompassCheckIntervalEnd
    case compassCheckTimeHour  // suggested Time for CC
    case compassCheckTimeMinute  // suggested Time for CC
    case accentColorString
    case expiryAfter
    case lastCompassCheckString
    case priority1
    case priority2
    case priority3
    case priority4
    case priority5

}

protocol KeyValueStorage {
    func int(forKey aKey: CloudKey) -> Int
    func set(_ value: Int, forKey aKey: CloudKey)

    func string(forKey aKey: CloudKey) -> String?
    func set(_ aString: String?, forKey aKey: CloudKey)

    func date(forKey aKey: CloudKey) -> Date
    func set(_ aDate: Date, forKey aKey: CloudKey)
}

extension KeyValueStorage {
    func string(forKey aKey: CloudKey, defaultValue: String) -> String {
        return string(forKey: aKey) ?? defaultValue
    }

    func date(forKey aKey: CloudKey) -> Date {
        if let dateAsString = string(forKey: aKey),
            let result = cloudDateFormatter.date(from: dateAsString)
        {
            return result
        }
        set(cloudDateFormatter.string(from: Date.now), forKey: .lastCompassCheckString)
        return Date.now
    }

    func set(_ aDate: Date, forKey aKey: CloudKey) {
        set(cloudDateFormatter.string(from: aDate), forKey: aKey)
    }
}

extension NSUbiquitousKeyValueStore: KeyValueStorage {

    func int(forKey aKey: CloudKey) -> Int {
        return Int(longLong(forKey: aKey.rawValue))
    }
    func set(_ value: Int, forKey aKey: CloudKey) {
        set(Int64(value), forKey: aKey.rawValue)
    }

    func string(forKey aKey: CloudKey) -> String? {
        return string(forKey: aKey.rawValue)
    }

    func set(_ aString: String?, forKey aKey: CloudKey) {
        set(aString, forKey: aKey.rawValue)
    }
}

@MainActor
@Observable
final class CloudPreferences {
    var store: KeyValueStorage
    typealias OnChange = () -> Void
    var onChange: OnChange?

    init(store: KeyValueStorage, onChange: OnChange? = nil) {
        self.store = store
        self.onChange = onChange
    }

    convenience init(testData: Bool, onChange: OnChange? = nil) {
        if testData {
            self.init(store: TestPreferences(), onChange: onChange)
        } else {
            self.init(store: NSUbiquitousKeyValueStore.default, onChange: onChange)

            NotificationCenter.default.addObserver(
                forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: self,
                queue: nil, using: ubiquitousKeyValueStoreDidChange)

            // initiate the store with a proper time
            if store.string(forKey: .lastCompassCheckString) == nil {
                store.set(18, forKey: .compassCheckTimeHour)
                store.set(00, forKey: .compassCheckTimeMinute)
            }
        }
    }

    func ubiquitousKeyValueStoreDidChange(notification: Notification) {
        if let onChange = onChange {
            onChange()
        }
    }
    
    var isProductionEnvironment: Bool {
            return CKContainer.isProductionEnvironment
        }

}

extension CloudPreferences {

    var daysOfCompassCheck: Int {
        get {
            let result = self.store.int(forKey: .daysOfCompassCheck)
            debugPrint("read daysOfCompassCheck: \(result), isStreakBroken: \(isStreakBroken)")
            return isStreakBroken ? 0: result
        }
        set {
            debugPrint("write new daysOfCompassCheck: \(newValue)")
            store.set(newValue, forKey: .daysOfCompassCheck)
        }
    }

    var nextCompassCheckTime: Date {
        var result = compassCheckTime
        if result < Date.now {
            result = addADay(result)
        }
        return result
    }

    var didCompassCheckToday: Bool {
        return getCompassCheckInterval().contains(lastCompassCheck)
    }
    
    private var didCompassCheckLastInterval: Bool {
        return getCompassCheckInterval(forDate: getDate(inDays: -1)).contains(lastCompassCheck)
    }
    
    var isStreakBroken: Bool {
        if didCompassCheckToday{
            return true
        }
        if didCompassCheckLastInterval{
            return true
        }
        return false
    }

    var compassCheckTime: Date {
        get {
            let compassCheckTimeHour = self.store.int(forKey: .compassCheckTimeHour)
            let compassCheckTimeMinute = self.store.int(forKey: .compassCheckTimeMinute)
            return todayAt(hour: compassCheckTimeHour, min: compassCheckTimeMinute)
        }
        set {
            self.store.set(newValue.hour, forKey: .compassCheckTimeHour)
            self.store.set(newValue.min, forKey: .compassCheckTimeMinute)
        }
    }

    var compassCheckTimeComponents: DateComponents {
        return DateComponents(
            calendar: getCal(), hour: self.store.int(forKey: .compassCheckTimeHour),
            minute: self.store.int(forKey: .compassCheckTimeMinute))
    }

    var longestStreak: Int {
        get {
            return store.int(forKey: .longestStreak)
        }
        set {
            store.set(newValue, forKey: .longestStreak)
        }
    }

    func resetAccentColor() {
        store.set(nil, forKey: .accentColorString)
    }

    var expiryAfter: Int {
        get {
            let result = self.store.int(forKey: .expiryAfter)
            if result < 9 {  // default is 0, and that is an issue!
                store.set(30, forKey: .expiryAfter)
                return 30
            }
            return result
        }
        set {
            store.set(newValue, forKey: .expiryAfter)
        }
    }

    var expiryAfterString: String {
        return expiryAfter.description
    }

    var lastCompassCheck: Date {
        get {
            if let dateAsString = store.string(forKey: .lastCompassCheckString),
                let result = cloudDateFormatter.date(from: dateAsString)
            {
                return result
            }
            store.set(cloudDateFormatter.string(from: Date.now), forKey: .lastCompassCheckString)
            return Date.now
        }
        set {
            store.set(cloudDateFormatter.string(from: newValue), forKey: .lastCompassCheckString)
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

    func getPriority(nr: Int) -> String {
        return store.string(forKey: nrToCloudKey(nr: nr)) ?? ""
    }

    func setPriority(nr: Int, value: String) {
        store.set(value, forKey: nrToCloudKey(nr: nr))
    }

}

class TestPreferences: KeyValueStorage {

    var values: [String: String] = [:]

    func int(forKey aKey: CloudKey) -> Int {
        return Int(values[aKey.rawValue] ?? "0") ?? 0
        //  debugPrint("reading \(result) for test_\(aKey.rawValue)")
    }

    func set(_ value: Int, forKey aKey: CloudKey) {
        //   debugPrint("setting test_\(aKey.rawValue) to \(value)")
        values[aKey.rawValue] = String(value)
    }

    func string(forKey aKey: CloudKey) -> String? {
        return values[aKey.rawValue]
    }

    func set(_ aString: String?, forKey aKey: CloudKey) {
        values[aKey.rawValue] = aString
    }
}

extension CKContainer {

    public static var isProductionEnvironment: Bool {
        let container = CKContainer.default()
        if let containerID = container.value(forKey: "containerID") as? NSObject {
            debugPrint("containerID: \(containerID)")
            return containerID.description.contains("Production")
        }
        return false
    }
}


@MainActor
func dummyPreferences() -> CloudPreferences {
    let store = TestPreferences()
    let result = CloudPreferences(store: store)
    result.daysOfCompassCheck = 42
    store.set(18, forKey: .compassCheckTimeHour)
    store.set(00, forKey: .compassCheckTimeMinute)
    return result
}
