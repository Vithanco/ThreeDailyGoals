import Foundation

extension Bundle {
    public static var safeSubsystem: String {
        Bundle.main.bundleIdentifier ?? "com.vithanco.three-daily-goals"
    }
}
