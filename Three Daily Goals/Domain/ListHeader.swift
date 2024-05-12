//
//  ListHeader.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 28/01/2024.
//

import Foundation


public struct ListHeader: Identifiable, Equatable, Sendable{
    
    let name: String
    let timeFrom: Int
    let timeTo: Int
    
    public var id: String {
        name
    }
    
    func filter(item: TaskItem) -> Bool {
        let fromDate = getDate(daysPrior: timeFrom)
        let toDate = timeTo == 0 ? Date.now : getDate(daysPrior: timeTo)
        return item.changed > fromDate && item.changed <= toDate
    }

    init(name: String, timeFrom: Int, timeTo: Int) {
        self.name = name
        self.timeTo = timeTo
        self.timeFrom = timeFrom
    }
    
    func filter(items: [TaskItem]) -> [TaskItem] {
        if items.count > 0 {
            return items.filter(self.filter).sorted(by:items.first!.state.sorter)
        }
        return []
    }
}

let lhToday = ListHeader(name: "Last 24h",  timeFrom: 1, timeTo: 0)
let lhYesterday = ListHeader(name: "Yesterday",  timeFrom: 2, timeTo: 1)
let lhLastWeek = ListHeader(name: "Last Week",  timeFrom: 7, timeTo: 2)
let lhLastMonth = ListHeader(name: "Last Month", timeFrom: 30, timeTo: 7)
let lhOlder = ListHeader(name: "over a year ago",  timeFrom: 1000000, timeTo: 365)
let lhLastQuarter = ListHeader(name: "Last Quarter",  timeFrom: 91, timeTo: 30)
let lhLastHalfYear = ListHeader(name: "Last Half Year", timeFrom: 182, timeTo: 91)

let all = ListHeader(name: "All", timeFrom: 1000000, timeTo: 0)

let defaultListHeaders = [lhOlder, lhLastHalfYear, lhLastQuarter, lhLastMonth, lhLastWeek, lhYesterday, lhToday]
