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


enum AppVersionProvider {
    static func appVersion(in bundle: Bundle = .main) -> String {
        guard let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            fatalError("CFBundleShortVersionString should not be missing from info dictionary")
        }
        return version
    }
}

