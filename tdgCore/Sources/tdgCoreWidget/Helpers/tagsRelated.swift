//
//  tagsRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 02/12/2025.
//

import Foundation

// MARK: - Standard Tags

/// Standard tags that are always available and cannot be deleted
public let standardTags = ["work", "private", "important", "non-important", "urgent", "non-urgent"]

// MARK: - Taggable Protocol

/// Protocol for objects that support tagging
public protocol Taggable {
    var tags: [String] { get }
    func addTag(_ newTag: String)
    func removeTag(_ oldTag: String)
}

// MARK: - Tag Icon

public let imgTag = "tag"
