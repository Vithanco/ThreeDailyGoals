//
//  ByteRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 21/08/2025.
//

import Foundation

func formatBytes(_ n: Int) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(n), countStyle: .file)
}
