import Foundation

@MainActor
protocol DataIssueReporter {
    func reportDatabaseError(_ error: DatabaseError)
    func reportDataLoss(_ message: String, details: String?)
    func reportMigrationIssue(_ message: String, details: String?)
}
