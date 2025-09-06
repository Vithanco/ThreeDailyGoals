//
//  TagRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 06/08/2025.
//

import SwiftUI
import TagKit

extension TagCapsuleStyle.Border {
    static let none: TagCapsuleStyle.Border = .init(
        color: .clear,
        width: 0
    )
}

public let missingTagStyle = TagCapsuleStyle(
    foregroundColor: .white,
    backgroundColor: .gray,
    border: .none,
    padding: .init(top: 1, leading: 3, bottom: 1, trailing: 3)
)

public func selectedTagStyle(accentColor: Color) -> TagCapsuleStyle {
    return TagCapsuleStyle(
        foregroundColor: accentColor.readableTextColor,
        backgroundColor: accentColor,
        border: .none,
        padding: .init(top: 1, leading: 3, bottom: 1, trailing: 3)
    )
}
