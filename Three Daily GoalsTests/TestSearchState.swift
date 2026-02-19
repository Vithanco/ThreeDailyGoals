//
//  TestSearchState.swift
//  Three Daily GoalsTests
//
//  Created by Claude on 19/02/2026.
//

import Foundation
import Testing

@testable import Three_Daily_Goals
@testable import tdgCoreMain

@Suite
@MainActor
struct TestSearchState {

    // MARK: - UIStateManager: Initial State

    @Test
    func initialState_isNotSearching() throws {
        let appComponents = setupApp(isTesting: true)
        let uiState = appComponents.uiState

        #expect(uiState.isSearching == false, "Should not be searching initially")
        #expect(uiState.searchText == "", "Search text should be empty initially")
    }

    // MARK: - UIStateManager: startSearch

    @Test
    func startSearch_setsIsSearchingToTrue() throws {
        let appComponents = setupApp(isTesting: true)
        let uiState = appComponents.uiState

        uiState.startSearch()

        #expect(uiState.isSearching == true, "isSearching should be true after startSearch()")
    }

    @Test
    func startSearch_preservesExistingSearchText() throws {
        let appComponents = setupApp(isTesting: true)
        let uiState = appComponents.uiState

        uiState.searchText = "existing query"
        uiState.startSearch()

        #expect(uiState.searchText == "existing query", "startSearch should not clear existing search text")
    }

    // MARK: - UIStateManager: stopSearch

    @Test
    func stopSearch_setsIsSearchingToFalse() throws {
        let appComponents = setupApp(isTesting: true)
        let uiState = appComponents.uiState

        uiState.startSearch()
        uiState.stopSearch()

        #expect(uiState.isSearching == false, "isSearching should be false after stopSearch()")
    }

    @Test
    func stopSearch_clearsSearchText() throws {
        let appComponents = setupApp(isTesting: true)
        let uiState = appComponents.uiState

        uiState.startSearch()
        uiState.searchText = "some query"
        uiState.stopSearch()

        #expect(uiState.searchText == "", "Search text should be cleared after stopSearch()")
    }

    // MARK: - UIStateManager: Search Text Binding

    @Test
    func searchText_canBeSetDirectly() throws {
        let appComponents = setupApp(isTesting: true)
        let uiState = appComponents.uiState

        uiState.searchText = "hello"
        #expect(uiState.searchText == "hello")

        uiState.searchText = "world"
        #expect(uiState.searchText == "world")

        uiState.searchText = ""
        #expect(uiState.searchText == "")
    }

    // MARK: - UIStateManager: Multiple Start/Stop Cycles

    @Test
    func multipleStartStopCycles_workCorrectly() throws {
        let appComponents = setupApp(isTesting: true)
        let uiState = appComponents.uiState

        // Cycle 1
        uiState.startSearch()
        #expect(uiState.isSearching == true)
        uiState.searchText = "query1"
        uiState.stopSearch()
        #expect(uiState.isSearching == false)
        #expect(uiState.searchText == "")

        // Cycle 2
        uiState.startSearch()
        #expect(uiState.isSearching == true)
        uiState.searchText = "query2"
        uiState.stopSearch()
        #expect(uiState.isSearching == false)
        #expect(uiState.searchText == "")
    }

    @Test
    func doubleStartSearch_doesNotBreakState() throws {
        let appComponents = setupApp(isTesting: true)
        let uiState = appComponents.uiState

        uiState.startSearch()
        uiState.startSearch()

        #expect(uiState.isSearching == true, "Double start should keep isSearching true")
    }

    @Test
    func doubleStopSearch_doesNotBreakState() throws {
        let appComponents = setupApp(isTesting: true)
        let uiState = appComponents.uiState

        uiState.startSearch()
        uiState.stopSearch()
        uiState.stopSearch()

        #expect(uiState.isSearching == false, "Double stop should keep isSearching false")
        #expect(uiState.searchText == "", "Double stop should keep searchText empty")
    }

    // MARK: - UIStateManager: clearAllDialogs does not affect search

    @Test
    func clearAllDialogs_doesNotAffectSearchState() throws {
        let appComponents = setupApp(isTesting: true)
        let uiState = appComponents.uiState

        uiState.startSearch()
        uiState.searchText = "active search"
        uiState.clearAllDialogs()

        #expect(uiState.isSearching == true, "clearAllDialogs should not affect search state")
        #expect(uiState.searchText == "active search", "clearAllDialogs should not clear search text")
    }

    // MARK: - Integration: Search State + DataManager

    @Test
    func searchTextChange_reflectedInDataManagerResults() throws {
        let loader: TestDataLoader = { timeProvider in
            var result: [TaskItem] = []
            result.add(title: "Alpha task", changedDate: timeProvider.getDate(daysPrior: 1), state: .open)
            result.add(title: "Beta task", changedDate: timeProvider.getDate(daysPrior: 2), state: .open)
            result.add(title: "Gamma task", changedDate: timeProvider.getDate(daysPrior: 3), state: .open)
            return result
        }
        let appComponents = setupApp(isTesting: true, loaderForTests: loader)
        let uiState = appComponents.uiState
        let dataManager = appComponents.dataManager

        uiState.startSearch()

        // Simulate typing "alpha"
        uiState.searchText = "alpha"
        let results = dataManager.searchTasks(query: uiState.searchText)
        #expect(results.count == 1)
        #expect(results.first?.title == "Alpha task")

        // Simulate changing query to "task"
        uiState.searchText = "task"
        let results2 = dataManager.searchTasks(query: uiState.searchText)
        #expect(results2.count == 3, "All tasks contain 'task' in the title")

        // Simulate clearing search
        uiState.stopSearch()
        let results3 = dataManager.searchTasks(query: uiState.searchText)
        #expect(results3.count == 3, "Empty query after stop should return all tasks")
    }
}
