//
//  ListHeader.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 28/01/2024.
//

import Foundation

public struct ListHeader: Identifiable, Equatable, Sendable {
    public let name: String
    public let timeFrom: Int
    public let timeTo: Int

    public var id: String {
        name
    }

    public init(name: String, timeFrom: Int, timeTo: Int) {
        self.name = name
        self.timeTo = timeTo
        self.timeFrom = timeFrom
        assert(
            timeFrom > timeTo || timeTo == 0,
            "timeFrom \(timeFrom) must be greater than timeTo \(timeTo) unless timeTo is 0")
    }

    public func filter(items: [TaskItem], timeProvider: TimeProvider) -> [TaskItem] {
        // Calculate dates once
        let fromDate = timeProvider.getDate(daysPrior: timeFrom)
        let toDate = timeTo == 0 ? timeProvider.getDate(inDays: 1000) : timeProvider.getDate(daysPrior: timeTo)

        // Use the same dates for all items
        let filteredItems = items.filter { item in
            item.changed > fromDate && item.changed <= toDate
        }

        // Sort the filtered items
        var sorter: TaskSorter = TaskItemState.youngestFirst
        if let first = filteredItems.first {
            sorter = first.state.sorter
        }

        return filteredItems.sorted(by: sorter)
    }

    public static let lhToday = ListHeader(name: "Last 24h", timeFrom: 1, timeTo: 0)
    public static let lhYesterday = ListHeader(name: "Yesterday", timeFrom: 2, timeTo: 1)
    public static let lhLastWeek = ListHeader(name: "Last Week", timeFrom: 7, timeTo: 2)
    public static let lhLastMonth = ListHeader(name: "Last Month", timeFrom: 30, timeTo: 7)
    public static let lhLastQuarter = ListHeader(name: "Last Quarter", timeFrom: 91, timeTo: 30)
    public static let lhLastHalfYear = ListHeader(name: "Last Half Year", timeFrom: 182, timeTo: 91)
    public static let lhPrevHalfYear = ListHeader(name: "Previous Half Year", timeFrom: 365, timeTo: 182)
    public static let lhPrevYear = ListHeader(name: "Previous Year", timeFrom: 730, timeTo: 365)
    public static let lh2ndYear = ListHeader(name: "Two Years ago", timeFrom: 1095, timeTo: 730)
    public static let lhOlder = ListHeader(name: "over Three Years ago", timeFrom: 1_000_000, timeTo: 1095)

    public static let all = ListHeader(name: "All", timeFrom: 1_000_000, timeTo: 0)

    public static let defaultListHeaders = [
        lhOlder, lh2ndYear, lhPrevYear, lhPrevHalfYear, lhLastHalfYear, lhLastQuarter, lhLastMonth,
        lhLastWeek, lhYesterday, lhToday,
    ]
}
