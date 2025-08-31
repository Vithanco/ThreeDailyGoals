import Foundation

@preconcurrency
protocol ItemSelector {
    func select(_ item: TaskItem)
}
