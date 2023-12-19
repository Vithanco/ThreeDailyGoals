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
            case .mainSection : return mainColor
            case .subSection: return secondaryColor
        }
    }
    
    var font: Font {
        switch self {
            case .mainSection : return .title
            case .subSection: return .title2
        }
    }
}

struct TaskSection{
    let text : String
    let image: String
    let style: SectionStyle
}

let secOpen = TaskSection(text: "Open", image: imgOpen, style: .mainSection)
let secClosed = TaskSection(text: "Closed", image: imgClosed, style: .mainSection)
let secGraveyard = TaskSection(text: "Graveyard", image: imgGraveyard, style: .mainSection)
let secLastWeek = TaskSection(text: "Last Week", image: imgDated, style: .subSection)
let secLastMonth = TaskSection(text: "Last Month", image: imgDated, style: .subSection)
let secOlder = TaskSection(text: "Older", image: imgDated, style: .subSection)


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
