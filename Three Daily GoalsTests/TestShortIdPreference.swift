import Foundation
import Testing

@testable import Three_Daily_Goals
@testable import tdgCoreWidget

@Suite
struct TestShortIdPreference {

    @Test
    @MainActor
    func defaultPrefixIsTDG() {
        let store = TestPreferences()
        let preferences = CloudPreferences(store: store, timeProvider: RealTimeProvider())
        #expect(preferences.shortIdPrefix == "TDG")
    }

    @Test
    @MainActor
    func setPrefixPersists() {
        let store = TestPreferences()
        let preferences = CloudPreferences(store: store, timeProvider: RealTimeProvider())
        preferences.shortIdPrefix = "BIZ"
        #expect(preferences.shortIdPrefix == "BIZ")
        #expect(store.string(forKey: StorageKeys.shortIdPrefix) == "BIZ")
    }

    @Test
    @MainActor
    func invalidPrefixFallsBackToDefault() {
        let store = TestPreferences()
        let preferences = CloudPreferences(store: store, timeProvider: RealTimeProvider())
        preferences.shortIdPrefix = ""
        #expect(preferences.shortIdPrefix == "TDG")
    }

    @Test
    @MainActor
    func prefixIsValidatedOnSet() {
        let store = TestPreferences()
        let preferences = CloudPreferences(store: store, timeProvider: RealTimeProvider())
        preferences.shortIdPrefix = "  biz  "
        #expect(preferences.shortIdPrefix == "BIZ")
    }
}
