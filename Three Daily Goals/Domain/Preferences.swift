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

struct StorageKeys {
    // Core app keys
    static let daysOfCompassCheck = "daysOfCompassCheck"
    static let longestStreak = "longestStreak"
    static let currentCompassCheckIntervalStart = "currentCompassCheckIntervalStart"
    static let currentCompassCheckIntervalEnd = "currentCompassCheckIntervalEnd"
    static let accentColorString = "accentColorString"
    static let expiryAfter = "expiryAfter"
    static let lastCompassCheckString = "lastCompassCheckString"
    
    // Compass check keys
    static let compassCheckTimeHour = "compassCheckTimeHour"
    static let compassCheckTimeMinute = "compassCheckTimeMinute"
    
    // Priority keys
    static func priority(_ number: Int) -> String {
        return "priority\(number)"
    }
    
    // Dynamic step keys
    static func compassCheckStep(_ stepId: String) -> String {
        return "compassCheck.step.\(stepId)"
    }
}

protocol KeyValueStorage {
    func int(forKey key: String) -> Int
    func set(_ value: Int, forKey key: String)

    func string(forKey key: String) -> String?
    func set(_ aString: String?, forKey key: String)

    func date(forKey key: String) -> Date
    func set(_ aDate: Date, forKey key: String)
    
    func bool(forKey key: String) -> Bool
    func set(_ value: Bool, forKey key: String)
}

extension KeyValueStorage {
    func string(forKey key: String, defaultValue: String) -> String {
        return string(forKey: key) ?? defaultValue
    }

    func date(forKey key: String) -> Date {
        if let dateAsString = string(forKey: key),
            let result = cloudDateFormatter.date(from: dateAsString)
        {
            return result
        }
        set(cloudDateFormatter.string(from: Date.now), forKey: StorageKeys.lastCompassCheckString)
        return Date.now
    }

    func set(_ aDate: Date, forKey key: String) {
        set(cloudDateFormatter.string(from: aDate), forKey: key)
    }
}

// Wrapper class to avoid infinite recursion
class CloudKeyValueStore: KeyValueStorage {
    private let store: NSUbiquitousKeyValueStore
    
    init(store: NSUbiquitousKeyValueStore) {
        self.store = store
    }
    
    func int(forKey key: String) -> Int {
        return Int(store.longLong(forKey: key))
    }
    
    func set(_ value: Int, forKey key: String) {
        store.set(Int64(value), forKey: key)
    }

    func string(forKey key: String) -> String? {
        return store.string(forKey: key)
    }

    func set(_ aString: String?, forKey key: String) {
        store.set(aString, forKey: key)
    }
    
    func bool(forKey key: String) -> Bool {
        return store.object(forKey: key) as? Bool ?? false
    }
    
    func set(_ value: Bool, forKey key: String) {
        store.set(value, forKey: key)
    }
}

@MainActor
@Observable
final class CloudPreferences {
    var store: KeyValueStorage
    let timeProvider: TimeProvider
    typealias OnChange = () -> Void
    var onChange: OnChange?
    
    // Stored properties that trigger @Observable notifications
    private var _daysOfCompassCheck: Int = 0
    private var _lastCompassCheck: Date = Date()

    init(store: KeyValueStorage, timeProvider: TimeProvider, onChange: OnChange? = nil) {
        self.store = store
        self.timeProvider = timeProvider
        self.onChange = onChange
        
        // Initialize stored properties from store
        self._daysOfCompassCheck = store.int(forKey: StorageKeys.daysOfCompassCheck)
        if let dateAsString = store.string(forKey: StorageKeys.lastCompassCheckString),
           let date = cloudDateFormatter.date(from: dateAsString) {
            self._lastCompassCheck = date
        } else {
            self._lastCompassCheck = timeProvider.now
        }
    }

    convenience init(testData: Bool, timeProvider: TimeProvider, onChange: OnChange? = nil) {
        if testData {
            self.init(store: TestPreferences(), timeProvider: timeProvider, onChange: onChange)
        } else {
            self.init(store: CloudKeyValueStore(store: NSUbiquitousKeyValueStore.default), timeProvider: timeProvider, onChange: onChange)

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleICloudChange(_:)),
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: NSUbiquitousKeyValueStore.default
            )

            if store.string(forKey: StorageKeys.lastCompassCheckString) == nil {
                store.set(18, forKey: StorageKeys.compassCheckTimeHour)
                store.set(0,  forKey: StorageKeys.compassCheckTimeMinute)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleICloudChange(_ note: Notification) {
        ubiquitousKeyValueStoreDidChange(notification: note)
    }

    func ubiquitousKeyValueStoreDidChange(notification: Notification) { 
        // Refresh stored properties when external changes occur
        _daysOfCompassCheck = store.int(forKey: StorageKeys.daysOfCompassCheck)
        if let dateAsString = store.string(forKey: StorageKeys.lastCompassCheckString),
           let date = cloudDateFormatter.date(from: dateAsString) {
            _lastCompassCheck = date
        }
        onChange?() 
    }

    var isProductionEnvironment: Bool { CKContainer.isProductionEnvironment }
}


extension CloudPreferences {

    var daysOfCompassCheck: Int {
        get {
            let result = isStreakBroken ? 0 : _daysOfCompassCheck
            debugPrint("read daysOfCompassCheck: \(result), isStreakBroken: \(isStreakBroken)")
            return result
        }
        set {
            debugPrint("write new daysOfCompassCheck: \(newValue)")
            _daysOfCompassCheck = newValue
            store.set(newValue, forKey: StorageKeys.daysOfCompassCheck)
        }
    }

    var nextCompassCheckTime: Date {
        var result = compassCheckTime
        if result < timeProvider.now {
            result = timeProvider.addADay(result)
        }
        return result
    }

    var didCompassCheckToday: Bool {
        return timeProvider.getCompassCheckInterval().contains(lastCompassCheck)
    }
    
    private var didCompassCheckLastInterval: Bool {
        // Get the current interval
        let currentInterval = timeProvider.getCompassCheckInterval()
        
        // Calculate the previous interval by going back 24 hours from the start of current interval
        let previousIntervalStart = timeProvider.calendar.date(byAdding: .day, value: -1, to: currentInterval.start) ?? currentInterval.start
        let previousInterval = DateInterval(start: previousIntervalStart, end: currentInterval.start)
        
        return previousInterval.contains(lastCompassCheck)
    }
    
    var isStreakActive: Bool {
        return didCompassCheckToday || didCompassCheckLastInterval
    }
    
    var isStreakBroken: Bool {
        let isActive = isStreakActive
        return !isActive
    }

    var compassCheckTime: Date {
        get {
            let compassCheckTimeHour = self.store.int(forKey: StorageKeys.compassCheckTimeHour)
            let compassCheckTimeMinute = self.store.int(forKey: StorageKeys.compassCheckTimeMinute)
            return timeProvider.todayAt(hour: compassCheckTimeHour, min: compassCheckTimeMinute)
        }
        set {
            self.store.set(timeProvider.hour(of: newValue), forKey: StorageKeys.compassCheckTimeHour)
            self.store.set(timeProvider.minute(of: newValue), forKey: StorageKeys.compassCheckTimeMinute)
        }
    }

    var compassCheckTimeComponents: DateComponents {
        return DateComponents(
            calendar: timeProvider.calendar, hour: self.store.int(forKey: StorageKeys.compassCheckTimeHour),
            minute: self.store.int(forKey: StorageKeys.compassCheckTimeMinute))
    }

    var longestStreak: Int {
        get {
            return store.int(forKey: StorageKeys.longestStreak)
        }
        set {
            store.set(newValue, forKey: StorageKeys.longestStreak)
        }
    }

    func resetAccentColor() {
        store.set(nil, forKey: StorageKeys.accentColorString)
    }

    var expiryAfter: Int {
        get {
            let result = self.store.int(forKey: StorageKeys.expiryAfter)
            if result < 9 {  // default is 0, and that is an issue!
                store.set(30, forKey: StorageKeys.expiryAfter)
                return 30
            }
            return result
        }
        set {
            store.set(newValue, forKey: StorageKeys.expiryAfter)
        }
    }

    var expiryAfterString: String {
        return expiryAfter.description
    }

    var lastCompassCheck: Date {
        get {
            return _lastCompassCheck
        }
        set {
            _lastCompassCheck = newValue
            store.set(cloudDateFormatter.string(from: newValue), forKey: StorageKeys.lastCompassCheckString)
        }
    }

    fileprivate func nrToCloudKey(nr: Int) -> String {
        return StorageKeys.priority(nr)
    }

    func getPriority(nr: Int) -> String {
        return store.string(forKey: nrToCloudKey(nr: nr)) ?? ""
    }

    func setPriority(nr: Int, value: String) {
        store.set(value, forKey: nrToCloudKey(nr: nr))
    }
    
    // MARK: - Compass Check Step Toggles
    
    /// Get the enabled state for a compass check step by its ID
    func isCompassCheckStepEnabled(stepId: String) -> Bool {
        // Use a dynamic approach: store step toggles in a single JSON object
        let stepTogglesKey = "compassCheckStepToggles" // Dedicated key for step toggles
        
        // Get the stored step toggles JSON
        guard let togglesJson = store.string(forKey: stepTogglesKey),
              let togglesData = togglesJson.data(using: .utf8),
              let toggles = try? JSONSerialization.jsonObject(with: togglesData) as? [String: Bool] else {
            // No stored toggles, return default values
            return getDefaultEnabledForStep(stepId: stepId)
        }
        
        // Return the stored value or default
        return toggles[stepId] ?? getDefaultEnabledForStep(stepId: stepId)
    }
    
    /// Set the enabled state for a compass check step by its ID
    func setCompassCheckStepEnabled(stepId: String, enabled: Bool) {
        // Use a dynamic approach: store step toggles in a single JSON object
        let stepTogglesKey = "compassCheckStepToggles" // Dedicated key for step toggles
        
        // Get existing toggles
        var toggles: [String: Bool] = [:]
        if let togglesJson = store.string(forKey: stepTogglesKey),
           let togglesData = togglesJson.data(using: .utf8),
           let existingToggles = try? JSONSerialization.jsonObject(with: togglesData) as? [String: Bool] {
            toggles = existingToggles
        }
        
        // Update the specific step
        toggles[stepId] = enabled
        
        // Store back as JSON
        if let togglesData = try? JSONSerialization.data(withJSONObject: toggles),
           let togglesJson = String(data: togglesData, encoding: .utf8) {
            store.set(togglesJson, forKey: stepTogglesKey)
        }
    }
    
    /// Get the default enabled state for a step
    private func getDefaultEnabledForStep(stepId: String) -> Bool {
        switch stepId {
        case "plan":
            return false // "coming soon"
        default:
            return true // all other steps enabled by default
        }
    }

}

class TestPreferences: KeyValueStorage {

    var values: [String: String] = [:]

    func int(forKey key: String) -> Int {
        return Int(values[key] ?? "0") ?? 0
    }

    func set(_ value: Int, forKey key: String) {
        values[key] = String(value)
    }

    func string(forKey key: String) -> String? {
        return values[key]
    }

    func set(_ aString: String?, forKey key: String) {
        values[key] = aString
    }
    
    func bool(forKey key: String) -> Bool {
        return values[key] == "true"
    }
    
    func set(_ value: Bool, forKey key: String) {
        values[key] = value ? "true" : "false"
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
    let result = CloudPreferences(store: store, timeProvider: RealTimeProvider())
    result.daysOfCompassCheck = 42
    store.set(18, forKey: StorageKeys.compassCheckTimeHour)
    store.set(00, forKey: StorageKeys.compassCheckTimeMinute)
    return result
}

