//
//  LoggingRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 12/01/2024.
//

extension Error {
    public func log() {
        debugPrint(self.localizedDescription)
    }
}
