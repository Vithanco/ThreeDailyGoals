import Foundation
import tdgCoreMain

@MainActor
public protocol ItemSelector {
    func select(_ item: TaskItem)
}
