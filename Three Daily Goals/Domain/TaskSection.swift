//
//  TaskSection.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import Foundation

public struct TaskSection: Observable, Sendable {
    let text: String
    let image: String
}

let secToday = TaskSection(text: "Today's Goals", image: imgPriority)
let secOpen = TaskSection(text: "Open", image: imgOpen)
let secClosed = TaskSection(text: "Closed", image: imgClosed)
let secGraveyard = TaskSection(text: "Graveyard", image: imgGraveyard)
let secPending = TaskSection(text: "Pending Response", image: imgPendingResponse)
let secDueSoon = TaskSection(text: "Due Soon", image: imgDueSoon)

extension TaskSection: Identifiable {
    public var id: String {
        return text
    }
}

//
//struct SubSection {
//    let text: String
//    let image: String
//    let style =  SectionStyle.subSection
//}
//
//let secLastWeek = SubSection(text: "Last Week", image: imgDated)
//let secLastMonth = SubSection(text: "Last Month", image: imgDated)
//let secOlder = SubSection(text: "Older", image: imgDated)
//
//struct TaskSection{
//    let text : String
//    let image: String
//    let style = SectionStyle.mainSection
//    let subSections: [SubSection]
//}
//
//let secOpen = TaskSection(text: "Open", image: imgOpen, subSections: [secLastWeek,secLastMonth])
//let secClosed = TaskSection(text: "Closed", image: imgClosed, subSections: [secLastWeek,secLastMonth,secOlder])
//let secGraveyard = TaskSection(text: "Graveyard", image: imgGraveyard, subSections: [secLastWeek,secLastMonth,secOlder])
