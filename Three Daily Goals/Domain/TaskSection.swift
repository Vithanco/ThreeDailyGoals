//
//  TaskSection.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import Foundation

public struct TaskSection : Observable , Sendable    {
    let text : String
    let image: String
    var showOlder: Bool
}

let secToday = TaskSection(text: "Today", image: imgToday,  showOlder: false)
let secOpen = TaskSection(text: "Open", image: imgOpen, showOlder: false)
let secClosed = TaskSection(text: "Closed", image: imgClosed, showOlder: true )
let secGraveyard = TaskSection(text: "Graveyard", image: imgGraveyard,  showOlder: true)
let secPending = TaskSection(text: "Pending Response", image: imgPendingResponse, showOlder: true)

extension TaskSection : Identifiable {
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
