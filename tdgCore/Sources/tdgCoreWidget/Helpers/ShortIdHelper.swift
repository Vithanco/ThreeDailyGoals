import Foundation

public enum TaskIdInput: Equatable, Sendable {
    case fullUUID(UUID)
    case shortHex(String)
}

public enum ShortIdHelper {

    public static let defaultPrefix = "TDG"

    public static func validatePrefix(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let filtered = String(trimmed.filter { $0.isASCII && $0.isLetter })
        guard filtered.count >= 2 && filtered.count <= 5 else {
            return defaultPrefix
        }
        return filtered
    }

    public static func shortId(from uuid: UUID, prefix: String) -> String {
        let hex = String(uuid.uuidString.prefix(8))
        return "\(prefix)-\(hex)"
    }

    public static func parseTaskId(_ input: String) -> TaskIdInput? {
        if let uuid = UUID(uuidString: input) {
            return .fullUUID(uuid)
        }
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if trimmed.count == 8, trimmed.allSatisfy({ $0.isHexDigit }) {
            return .shortHex(trimmed)
        }
        if let dashIndex = trimmed.lastIndex(of: "-") {
            let hexPart = String(trimmed[trimmed.index(after: dashIndex)...])
            if hexPart.count == 8, hexPart.allSatisfy({ $0.isHexDigit }) {
                return .shortHex(hexPart)
            }
        }
        return nil
    }
}
