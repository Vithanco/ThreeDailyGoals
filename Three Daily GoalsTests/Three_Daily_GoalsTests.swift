//
//  Three_Daily_GoalsTests.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import XCTest
@testable import Three_Daily_Goals

final class Three_Daily_GoalsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAppStartsEmpty() throws {
        let container = sharedModelContainer(inMemory: true)

        let sut = ContentView.ViewModel(modelContext: container.mainContext)

        XCTAssertEqual(sut.movies.count, 0, "There should be 0 movies when the app is first launched.")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
