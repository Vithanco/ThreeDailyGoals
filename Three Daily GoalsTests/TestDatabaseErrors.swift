//
//  TestDatabaseErrors.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 23/08/2025.
//

import XCTest
@testable import Three_Daily_Goals

final class TestDatabaseErrors: XCTestCase {

    func testDatabaseErrorTypes() {
        // Test migration failed error
        let migrationError = DatabaseError.migrationFailed(underlyingError: NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Migration failed"]))
        
        XCTAssertTrue(migrationError.isUpgradeRequired)
        XCTAssertEqual(migrationError.userFriendlyTitle, "App Update Required")
        XCTAssertTrue(migrationError.userFriendlyMessage.contains("update"))
        
        // Test CloudKit sync error
        let syncError = DatabaseError.cloudKitSyncFailed(underlyingError: NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Sync failed"]))
        
        XCTAssertFalse(syncError.isUpgradeRequired)
        XCTAssertEqual(syncError.userFriendlyTitle, "Sync Error")
        XCTAssertTrue(syncError.userFriendlyMessage.contains("internet"))
    }
    
    func testDatabaseErrorRecoverySuggestions() {
        let migrationError = DatabaseError.migrationFailed(underlyingError: NSError(domain: "test", code: 1))
        let syncError = DatabaseError.cloudKitSyncFailed(underlyingError: NSError(domain: "test", code: 2))
        
        XCTAssertTrue(migrationError.recoverySuggestion?.contains("update") ?? false)
        XCTAssertTrue(syncError.recoverySuggestion?.contains("internet") ?? false)
    }
    
    func testUIStateManagerDatabaseErrorHandling() {
        let uiState = UIStateManager()
        let testError = DatabaseError.unsupportedSchemaVersion
        
        // Initially no error should be shown
        XCTAssertFalse(uiState.showDatabaseErrorAlert)
        XCTAssertNil(uiState.databaseError)
        
        // Show database error
        uiState.showDatabaseError(testError)
        
        // Error should now be set and alert should be shown
        XCTAssertTrue(uiState.showDatabaseErrorAlert)
        XCTAssertNotNil(uiState.databaseError)
        XCTAssertEqual(uiState.databaseError?.userFriendlyTitle, "App Update Required")
    }
    
    func testDataIssueReporterProtocol() {
        let uiState = UIStateManager()
        let testError = DatabaseError.migrationFailed(underlyingError: NSError(domain: "test", code: 1))
        
        // Initially no error should be shown
        XCTAssertFalse(uiState.showDatabaseErrorAlert)
        XCTAssertNil(uiState.databaseError)
        
        // Use protocol method to report database error
        uiState.reportDatabaseError(testError)
        
        // Error should now be set and alert should be shown
        XCTAssertTrue(uiState.showDatabaseErrorAlert)
        XCTAssertNotNil(uiState.databaseError)
        XCTAssertEqual(uiState.databaseError?.userFriendlyTitle, "App Update Required")
    }
    
    func testMigrationIssueReporting() {
        let uiState = UIStateManager()
        
        // Initially no info message should be shown
        XCTAssertFalse(uiState.showInfoMessage)
        
        // Report a migration issue
        uiState.reportMigrationIssue("Test migration issue", details: "Test details")
        
        // Info message should now be shown with migration issue content
        XCTAssertTrue(uiState.showInfoMessage)
        XCTAssertTrue(uiState.infoMessage.contains("Migration Issue"))
        XCTAssertTrue(uiState.infoMessage.contains("Test migration issue"))
        XCTAssertTrue(uiState.infoMessage.contains("Test details"))
    }
    
    func testDataLossReporting() {
        let uiState = UIStateManager()
        
        // Initially no info message should be shown
        XCTAssertFalse(uiState.showInfoMessage)
        
        // Report data loss
        uiState.reportDataLoss("Test data loss", details: "Test details")
        
        // Info message should now be shown with data loss content
        XCTAssertTrue(uiState.showInfoMessage)
        XCTAssertTrue(uiState.infoMessage.contains("Data Loss Warning"))
        XCTAssertTrue(uiState.infoMessage.contains("Test data loss"))
        XCTAssertTrue(uiState.infoMessage.contains("Test details"))
    }
}
