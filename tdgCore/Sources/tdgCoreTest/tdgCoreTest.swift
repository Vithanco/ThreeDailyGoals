//
//  tdgCoreTest.swift
//  tdgCoreTest
//
//  Created by AI Assistant on 2025-09-18.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers
/// Test utilities and helpers for Three Daily Goals testing
///
/// This module provides shared test utilities that can be used by both
/// unit tests and UI tests across the Three Daily Goals project.
///
/// ## Usage
///
/// ```swift
/// import tdgCoreTest
///
/// // Create mock data for testing
/// let provider = ShareExtensionTestUtilities.createMockProvider(text: "Test task")
///
/// // Create test scenarios
/// let scenario = ShareTestScenario.text("Test content")
/// ```
@_exported import tdgCoreShare

// Re-export the test utilities for easy access
// The utilities are already available through the module import
