import Foundation

import tdgCoreMain

@MainActor
public protocol PriorityUpdater {
    func updatePriorities(prioTasks: [TaskItem])
}
