import Foundation

@MainActor
protocol PriorityUpdater {
    func updatePriorities(prioTasks: [TaskItem])
}
