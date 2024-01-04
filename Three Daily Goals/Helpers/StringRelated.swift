//
//  StringRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import Foundation


extension String.StringInterpolation {
    mutating func appendInterpolation(_ date: Date) {
        appendLiteral(date.formatted(stdDateFormat) )
    }
}


