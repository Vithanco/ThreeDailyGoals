//
//  ListHeader.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 28/01/2024.
//

import Foundation

public struct ListHeader: Identifiable, Equatable, Sendable {
    let name: String
    let timeFrom: Int
    let timeTo: Int
    let fromDate: Date
    let toDate: Date

    public var id: String {
        name
    }

    func filter(item: TaskItem) -> Bool {
        return item.changed > fromDate && item.changed <= toDate
    }

    init(name: String, timeFrom: Int, timeTo: Int) {
        self.name = name
        self.timeTo = timeTo
        self.timeFrom = timeFrom
        self.fromDate = getDate(daysPrior: timeFrom)
        self.toDate = timeTo == 0 ? getDate(inDays: 1000) : getDate(daysPrior: timeTo)
        assert(fromDate < toDate, "fromDate \(fromDate) must be earlier than toDate \(toDate)")
    }

    func filter(items: [TaskItem]) -> [TaskItem] {
        var sorter: TaskSorter = TaskItemState.youngestFirst
        if let first = items.first {
            sorter = first.state.sorter
        }
        return items.filter(filter).sorted(by: sorter)
    }

    static let lhToday = ListHeader(name: "Last 24h", timeFrom: 1, timeTo: 0)
    static let lhYesterday = ListHeader(name: "Yesterday", timeFrom: 2, timeTo: 1)
    static let lhLastWeek = ListHeader(name: "Last Week", timeFrom: 7, timeTo: 2)
    static let lhLastMonth = ListHeader(name: "Last Month", timeFrom: 30, timeTo: 7)
    static let lhLastQuarter = ListHeader(name: "Last Quarter", timeFrom: 91, timeTo: 30)
    static let lhLastHalfYear = ListHeader(name: "Last Half Year", timeFrom: 182, timeTo: 91)
    static let lhPrevHalfYear = ListHeader(name: "Previous Half Year", timeFrom: 365, timeTo: 182)
    static let lhPrevYear = ListHeader(name: "Previous Year", timeFrom: 730, timeTo: 365)
    static let lh2ndYear = ListHeader(name: "Two Years ago", timeFrom: 1095, timeTo: 730)
    static let lhOlder = ListHeader(name: "over Three Years ago", timeFrom: 1_000_000, timeTo: 1095)

    static let all = ListHeader(name: "All", timeFrom: 1_000_000, timeTo: 0)

    static let defaultListHeaders = [
        lhOlder, lh2ndYear, lhPrevYear, lhPrevHalfYear, lhLastHalfYear, lhLastQuarter, lhLastMonth,
        lhLastWeek, lhYesterday, lhToday,
    ]
}
