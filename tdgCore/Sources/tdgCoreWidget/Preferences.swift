//  Preferences.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 28/01/2024.
//

import CloudKit
import Foundation
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

public struct StorageKeys: Sendable {
    public let id: String

    private init(_ id: String) {
        self.id = id
    }

    // Core app keys
    public static let daysOfCompassCheck = StorageKeys("daysOfCompassCheck")
    public static let longestStreak = StorageKeys("longestStreak")
    public static let currentCompassCheckIntervalStart = StorageKeys("currentCompassCheckIntervalStart")
    public static let currentCompassCheckIntervalEnd = StorageKeys("currentCompassCheckIntervalEnd")
    public static let accentColorString = StorageKeys("accentColorString")
    public static let expiryAfter = StorageKeys("expiryAfter")
    public static let lastCompassCheckString = StorageKeys("lastCompassCheckString")

    // Compass check keys
    public static let compassCheckTimeHour = StorageKeys("compassCheckTimeHour")
    public static let compassCheckTimeMinute = StorageKeys("compassCheckTimeMinute")
    public static let currentCompassCheckStepId = StorageKeys("currentCompassCheckStepId")
    public static let currentCompassCheckPeriodStart = StorageKeys("currentCompassCheckPeriodStart")

    // Priority keys
    public static func priority(_ number: Int) -> StorageKeys {
        return StorageKeys("priority\(number)")
    }

    // Priority UUID keys
    public static func priorityUUID(_ number: Int) -> StorageKeys {
        return StorageKeys("priorityUUID\(number)")
    }

    // Dynamic step keys
    public static func compassCheckStepIsEnabledKey(_ stepId: String) -> StorageKeys {
        return StorageKeys("compassCheck.step.\(stepId)")
    }

    // Notifications key
    public static let notificationsEnabled = StorageKeys("notificationsEnabled")

    // Calendar integration key
    public static let targetCalendarIdentifier = StorageKeys("targetCalendarIdentifier")
}

public protocol KeyValueStorage {
    func int(forKey key: StorageKeys) -> Int
    func set(_ value: Int, forKey key: StorageKeys)

    func string(forKey key: StorageKeys) -> String?
    func set(_ aString: String?, forKey key: StorageKeys)

    func date(forKey key: StorageKeys) -> Date
    func set(_ aDate: Date, forKey key: StorageKeys)

    func bool(forKey key: StorageKeys, default defaultValue: Bool) -> Bool
    func set(_ value: Bool, forKey key: StorageKeys)
}

extension KeyValueStorage {
    public func string(forKey key: StorageKeys, defaultValue: String) -> String {
        return string(forKey: key) ?? defaultValue
    }

    public func date(forKey key: StorageKeys) -> Date {
        if let dateAsString = string(forKey: key),
            let result = cloudDateFormatter.date(from: dateAsString)
        {
            return result
        }
        set(cloudDateFormatter.string(from: Date.now), forKey: StorageKeys.lastCompassCheckString)
        return Date.now
    }

    public func set(_ aDate: Date, forKey key: StorageKeys) {
        set(cloudDateFormatter.string(from: aDate), forKey: key)
    }
}

// Wrapper class to avoid infinite recursion
public class CloudKeyValueStore: KeyValueStorage {
    private let store: NSUbiquitousKeyValueStore

    public init(store: NSUbiquitousKeyValueStore) {
        self.store = store
    }

    public func int(forKey key: StorageKeys) -> Int {
        return Int(store.longLong(forKey: key.id))
    }

    public func set(_ value: Int, forKey key: StorageKeys) {
        store.set(Int64(value), forKey: key.id)
    }

    public func string(forKey key: StorageKeys) -> String? {
        return store.string(forKey: key.id)
    }

    public func set(_ aString: String?, forKey key: StorageKeys) {
        store.set(aString, forKey: key.id)
    }

    public func bool(forKey key: StorageKeys, default defaultValue: Bool) -> Bool {
        return store.object(forKey: key.id) as? Bool ?? defaultValue
    }

    public func set(_ value: Bool, forKey key: StorageKeys) {
        store.set(value, forKey: key.id)
    }
}

@MainActor
@Observable
final public class CloudPreferences {
    var store: KeyValueStorage
    let timeProvider: TimeProvider
    public typealias OnChange = () -> Void
    public var onChange: OnChange?

    // Stored properties that trigger @Observable notifications
    private var _daysOfCompassCheck: Int = 0
    private var _lastCompassCheck: Date = Date()
    private var _expiryAfter: Int = 30
    private var _compassCheckStepToggles: [String: Bool] = [:]

    public init(store: KeyValueStorage, timeProvider: TimeProvider = RealTimeProvider(), onChange: OnChange? = nil) {
        self.store = store
        self.timeProvider = timeProvider
        self.onChange = onChange

        // Initialize stored properties from store
        self._daysOfCompassCheck = store.int(forKey: StorageKeys.daysOfCompassCheck)
        if let dateAsString = store.string(forKey: StorageKeys.lastCompassCheckString),
            let date = cloudDateFormatter.date(from: dateAsString)
        {
            self._lastCompassCheck = date
        } else {
            self._lastCompassCheck = timeProvider.now
        }

        // Initialize expiryAfter with proper default handling
        let storedExpiry = store.int(forKey: StorageKeys.expiryAfter)
        if storedExpiry < 9 {
            self._expiryAfter = 30
            store.set(30, forKey: StorageKeys.expiryAfter)
        } else {
            self._expiryAfter = storedExpiry
        }

        // Initialize compass check step toggles
        self._compassCheckStepToggles = [:]
    }

    public convenience init(testData: Bool, timeProvider: TimeProvider, onChange: OnChange? = nil) {
        if testData {
            self.init(store: TestPreferences(), timeProvider: timeProvider, onChange: onChange)
        } else {
            self.init(
                store: CloudKeyValueStore(store: NSUbiquitousKeyValueStore.default), timeProvider: timeProvider,
                onChange: onChange)

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleICloudChange(_:)),
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: NSUbiquitousKeyValueStore.default
            )

            if store.string(forKey: StorageKeys.lastCompassCheckString) == nil {
                store.set(18, forKey: StorageKeys.compassCheckTimeHour)
                store.set(0, forKey: StorageKeys.compassCheckTimeMinute)
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
            let date = cloudDateFormatter.date(from: dateAsString)
        {
            _lastCompassCheck = date
        }
        _expiryAfter = store.int(forKey: StorageKeys.expiryAfter)
        // Clear the cache so values are reloaded on next access
        _compassCheckStepToggles = [:]
        onChange?()
    }

    public var isProductionEnvironment: Bool { CKContainer.isProductionEnvironment }
}

extension CloudPreferences {

    public var daysOfCompassCheck: Int {
        get {
            let result = isStreakBroken ? 0 : _daysOfCompassCheck
            return result
        }
        set {
            _daysOfCompassCheck = newValue
            store.set(newValue, forKey: StorageKeys.daysOfCompassCheck)
        }
    }

    public var nextCompassCheckTime: Date {
        var result = compassCheckTime
        if result < timeProvider.now {
            result = timeProvider.addADay(result)
        }
        return result
    }

    public var didCompassCheckToday: Bool {
        return timeProvider.getCompassCheckInterval().contains(lastCompassCheck)
    }

    private var didCompassCheckLastInterval: Bool {
        // Get the current interval
        let currentInterval = timeProvider.getCompassCheckInterval()

        // Calculate the previous interval by going back 24 hours from the start of current interval
        let previousIntervalStart =
            timeProvider.calendar.date(byAdding: .day, value: -1, to: currentInterval.start) ?? currentInterval.start
        let previousInterval = DateInterval(start: previousIntervalStart, end: currentInterval.start)

        return previousInterval.contains(lastCompassCheck)
    }

    public var isStreakActive: Bool {
        return didCompassCheckToday || didCompassCheckLastInterval
    }

    public var isStreakBroken: Bool {
        let isActive = isStreakActive
        return !isActive
    }

    public var compassCheckTime: Date {
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

    public var compassCheckTimeComponents: DateComponents {
        return DateComponents(
            calendar: timeProvider.calendar, hour: self.store.int(forKey: StorageKeys.compassCheckTimeHour),
            minute: self.store.int(forKey: StorageKeys.compassCheckTimeMinute))
    }

    public var longestStreak: Int {
        get {
            return store.int(forKey: StorageKeys.longestStreak)
        }
        set {
            store.set(newValue, forKey: StorageKeys.longestStreak)
        }
    }

    public func resetAccentColor() {
        store.set(nil, forKey: StorageKeys.accentColorString)
    }

    public var expiryAfter: Int {
        get {
            return _expiryAfter
        }
        set {
            _expiryAfter = newValue
            store.set(newValue, forKey: StorageKeys.expiryAfter)
            onChange?()
        }
    }

    public var expiryAfterString: String {
        return expiryAfter.description
    }

    public var lastCompassCheck: Date {
        get {
            return _lastCompassCheck
        }
        set {
            _lastCompassCheck = newValue
            store.set(cloudDateFormatter.string(from: newValue), forKey: StorageKeys.lastCompassCheckString)
        }
    }

    fileprivate func nrToCloudKey(nr: Int) -> StorageKeys {
        return StorageKeys.priority(nr)
    }

    public func getPriority(nr: Int) -> String {
        let key = nrToCloudKey(nr: nr)
        let value = store.string(forKey: key) ?? ""
        return value
    }

    public func setPriority(nr: Int, value: String) {
        store.set(value, forKey: nrToCloudKey(nr: nr))
    }

    public func getPriorityUUID(nr: Int) -> String {
        let key = StorageKeys.priorityUUID(nr)
        let value = store.string(forKey: key) ?? ""
        return value
    }

    public func setPriorityUUID(nr: Int, value: String) {
        store.set(value, forKey: StorageKeys.priorityUUID(nr))
    }

    // MARK: - Compass Check Step Toggles

    /// Get the enabled state for a compass check step by its ID
    public func isCompassCheckStepEnabled(stepId: String) -> Bool {
        // Check if we have it in memory
        if let cachedValue = _compassCheckStepToggles[stepId] {
            return cachedValue
        }

        // Load from storage with step-specific default
        let stepKey = StorageKeys.compassCheckStepIsEnabledKey(stepId)
        let defaultValue = getDefaultEnabledForStep(stepId: stepId)
        let storedValue = store.bool(forKey: stepKey, default: defaultValue)

        // Cache the value
        _compassCheckStepToggles[stepId] = storedValue
        return storedValue
    }

    /// Set the enabled state for a compass check step by its ID
    public func setCompassCheckStepEnabled(stepId: String, enabled: Bool) {
        // Update the private variable
        _compassCheckStepToggles[stepId] = enabled

        // Store to persistent storage using individual key
        let stepKey = StorageKeys.compassCheckStepIsEnabledKey(stepId)
        store.set(enabled, forKey: stepKey)

        // Trigger UI update
        onChange?()
    }

    /// Get the default enabled state for a step
    private func getDefaultEnabledForStep(stepId: String) -> Bool {
        switch stepId {
        case "plan":
            return false  // "coming soon"
        default:
            return true  // all other steps enabled by default
        }
    }

    // MARK: - Notifications

    public var notificationsEnabled: Bool {
        get {
            return store.bool(forKey: StorageKeys.notificationsEnabled, default: true)
        }
        set {
            store.set(newValue, forKey: StorageKeys.notificationsEnabled)
        }
    }

    // MARK: - Calendar Integration

    /// The calendar identifier for scheduling tasks
    public var targetCalendarId: String? {
        get {
            return store.string(forKey: StorageKeys.targetCalendarIdentifier)
        }
        set {
            store.set(newValue, forKey: StorageKeys.targetCalendarIdentifier)
            onChange?()
        }
    }

    // MARK: - Compass Check Progress Persistence

    /// The ID of the current compass check step
    public var currentCompassCheckStepId: String? {
        get {
            return store.string(forKey: StorageKeys.currentCompassCheckStepId)
        }
        set {
            store.set(newValue, forKey: StorageKeys.currentCompassCheckStepId)
        }
    }

    /// The start of the compass check period when CC began
    public var currentCompassCheckPeriodStart: Date? {
        get {
            guard let dateString = store.string(forKey: StorageKeys.currentCompassCheckPeriodStart),
                let date = cloudDateFormatter.date(from: dateString)
            else {
                return nil
            }
            return date
        }
        set {
            if let date = newValue {
                store.set(cloudDateFormatter.string(from: date), forKey: StorageKeys.currentCompassCheckPeriodStart)
            } else {
                store.set(nil, forKey: StorageKeys.currentCompassCheckPeriodStart)
            }
        }
    }

    /// Clear the compass check progress (when finished or cancelled)
    public func clearCompassCheckProgress() {
        currentCompassCheckStepId = nil
        currentCompassCheckPeriodStart = nil
    }

}

public class TestPreferences: KeyValueStorage {

    var values: [String: String]

    public init(values: [String: String] = [:]) {
        self.values = values
    }

    public func int(forKey key: StorageKeys) -> Int {
        return Int(values[key.id] ?? "0") ?? 0
    }

    public func set(_ value: Int, forKey key: StorageKeys) {
        values[key.id] = String(value)
    }

    public func string(forKey key: StorageKeys) -> String? {
        return values[key.id]
    }

    public func set(_ aString: String?, forKey key: StorageKeys) {
        values[key.id] = aString
    }

    public func bool(forKey key: StorageKeys, default defaultValue: Bool) -> Bool {
        guard let value = values[key.id] else { return defaultValue }
        return value == "true"
    }

    public func set(_ value: Bool, forKey key: StorageKeys) {
        values[key.id] = value ? "true" : "false"
    }
}

extension CKContainer {

    public static var isProductionEnvironment: Bool {
        let container = CKContainer.default()
        if let containerID = container.value(forKey: "containerID") as? NSObject {
            //  debugPrint("containerID: \(containerID)")
            return containerID.description.contains("Production")
        }
        return false
    }
}

@MainActor
public func dummyPreferences() -> CloudPreferences {
    let store = TestPreferences()
    let result = CloudPreferences(store: store, timeProvider: RealTimeProvider())
    result.daysOfCompassCheck = 42
    store.set(18, forKey: StorageKeys.compassCheckTimeHour)
    store.set(00, forKey: StorageKeys.compassCheckTimeMinute)
    return result
}
