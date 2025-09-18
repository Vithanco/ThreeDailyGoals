import Foundation
import tdgCoreMain

@MainActor
public protocol DataIssueReporter {
    func reportDatabaseError(_ error: DatabaseError)
    func reportDataLoss(_ message: String, details: String?)
    func reportMigrationIssue(_ message: String, details: String?)
}
