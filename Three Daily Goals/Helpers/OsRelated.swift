import Foundation
import SwiftUI

enum SupportedOS {
    case iOS
    case macOS
    case ipadOS
}

struct OsRelated {
    static var currentOS: SupportedOS {
        #if os(iOS)
            if isLargeDevice {
                return .ipadOS
            }
            return .iOS
        #elseif os(macOS)
            return .macOS
        #endif
    }

    private static var isLargeDevice: Bool {
        // This would need to be implemented based on your existing logic
        // For now, returning false as placeholder
        return false
    }
}
