//
//  TaskSection.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import Foundation
import SwiftUI

enum SectionStyle {
    case mainSection
    case subSection
    
    var color: Color {
        switch self {
            case .mainSection : return .mainColor
            case .subSection: return .secondaryColor
        }
    }
    
    var font: Font {
        switch self {
            case .mainSection : return .title
            case .subSection: return .title2
        }
    }
}

struct TaskSection : Observable     {
    let text : String
    let image: String
    let style: SectionStyle
    var showOlder: Bool
}

let secToday = TaskSection(text: "Today", image: imgToday, style: .mainSection, showOlder: false)
let secOpen = TaskSection(text: "Open", image: imgOpen, style: .mainSection, showOlder: false)
let secClosed = TaskSection(text: "Closed", image: imgClosed, style: .mainSection, showOlder: true )
let secGraveyard = TaskSection(text: "Graveyard", image: imgGraveyard, style: .mainSection, showOlder: true)
let secPending = TaskSection(text: "Pending Response", image: imgPendingResponse, style: .mainSection, showOlder: true)



extension TaskSection {
    var asText: Text {
        return Text("\(Image(systemName: image)) \(text)").font(style.font).foregroundStyle(style.color)
    }
}

extension TaskSection : Identifiable {
    var id: String {
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
