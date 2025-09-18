import Foundation
import SwiftUI

public enum SupportedOS {
    case iOS
    case macOS
    case ipadOS
}

public struct OsRelated {
    public static var currentOS: SupportedOS {
        #if os(iOS)
            if isLargeDevice {
                return .ipadOS
            }
            return .iOS
        #elseif os(macOS)
            return .macOS
        #endif
    }
}
