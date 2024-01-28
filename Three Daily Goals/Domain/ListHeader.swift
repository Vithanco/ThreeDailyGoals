//
//  ListHeader.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 28/01/2024.
//

import Foundation


struct ListHeader: Identifiable{
    
    let name: String
    let timeFrom: Int
    let timeTo: Int
    
    var id: String {
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
}


let secLastWeek = ListHeader(name: "Last Week",  timeFrom: 7, timeTo: 0)
let secLastMonth = ListHeader(name: "Last Month", timeFrom: 30, timeTo: 7)
let secOlder = ListHeader(name: "over a year ago",  timeFrom: 1000000, timeTo: 365)
let secLastQuarter = ListHeader(name: "Last Quarter",  timeFrom: 91, timeTo: 30)
let secLastHalfYear = ListHeader(name: "Last Half Year", timeFrom: 182, timeTo: 91)

let defaultListHeaders = [secOlder, secLastHalfYear, secLastQuarter, secLastMonth, secLastWeek]
