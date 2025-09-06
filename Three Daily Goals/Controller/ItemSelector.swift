import Foundation

@MainActor
protocol ItemSelector {
    func select(_ item: TaskItem)
}
