//
//  DataManager.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 14/01/2025.
//

import Foundation
import SwiftUI
import SwiftData
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: DataManager.self)
)

@MainActor
@Observable
final class DataManager {
    
    let modelContext: Storage
    
    // Core data properties
    var items = [TaskItem]()
    var lists: [TaskItemState: [TaskItem]] = [:]
    
    init(modelContext: Storage) {
        self.modelContext = modelContext
        
        // Initialize lists for all states
        for state in TaskItemState.allCases {
            lists[state] = []
        }
    }
    
    // MARK: - Data Access
    
    /// Get all tasks for a specific state
    func list(which state: TaskItemState) -> [TaskItem] {
        guard let result = lists[state] else {
            logger.fault("couldn't retrieve list \(state) from lists")
            return []
        }
        return result
    }
    
    /// Get all tasks
    var allTasks: [TaskItem] {
        return items
    }
    
    /// Get all active tags across all tasks
    var activeTags: Set<String> {
        var result = Set<String>()
        for t in items where !t.tags.isEmpty && t.isActive {
            result.formUnion(t.tags)
        }
        return result
    }
    
    // MARK: - Task Operations
    
    /// Find a task by UUID string
    func findTask(withUuidString uuidString: String) -> TaskItem? {
        guard let uuid = UUID(uuidString: uuidString) else { return nil }
        
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.uuid == uuid
            }
        )
        
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            logger.error("Failed to find task with UUID \(uuidString): \(error)")
            return nil
        }
    }
    
    /// Move a task to a different state
    func move(task: TaskItem, to state: TaskItemState) {
        if task.state == state {
            return  // nothing to be done
        }
        
        // Remove from old list
        lists[task.state]?.removeObject(task)
        
        // Update task state
        task.state = state
        
        // Add to new list
        lists[state]?.append(task)
        sortList(state)
        
        save()
    }
    
    /// Create a new task
    func createTask(title: String, state: TaskItemState = .open) -> TaskItem {
        let task = TaskItem(title: title, state: state)
        addExistingTask(task)
        return task
    }
    
    /// Add an existing task to the data manager
    func addExistingTask(_ task: TaskItem) {
        modelContext.insert(task)
        items.append(task)
        lists[task.state]?.append(task)
        sortList(task.state)
        save()
    }
    
    /// Delete a task
    func deleteTask(_ task: TaskItem) {
        // Remove from lists
        lists[task.state]?.removeObject(task)
        
        // Remove from items array
        if let index = items.firstIndex(of: task) {
            items.remove(at: index)
        }
        
        // Delete comments first
        for c in task.comments ?? [] {
            modelContext.delete(c)
        }
        
        // Delete from database
        modelContext.delete(task)
        save()
    }
    
    /// Delete multiple tasks
    func deleteTasks(_ tasks: [TaskItem]) {
        for task in tasks {
            modelContext.delete(task)
        }
        save()
    }
    
    /// Duplicate a task
    func duplicateTask(_ task: TaskItem) -> TaskItem {
        let newTask = TaskItem(
            title: task.title,
            state: task.state
        )
        
        // Copy comments
        if let comments = task.comments {
            for comment in comments {
                let newComment = Comment(text: comment.text, taskItem: newTask)
                newTask.comments?.append(newComment)
            }
        }
        
        modelContext.insert(newTask)
        save()
        return newTask
    }
    
    /// Toggle task completion
    func toggleCompletion(for task: TaskItem) {
        switch task.state {
        case .open, .priority:
            task.state = .closed
        case .closed:
            task.state = .open
        case .dead, .pendingResponse:
            // Dead and pending tasks can't be toggled
            break
        }
        save()
    }
    
    /// Archive completed tasks older than specified days
    func archiveCompletedTasks(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        // Get all closed tasks and filter them in memory since the predicate is complex
        let closedTasks = list(which: .closed)
        let tasksToArchive = closedTasks.filter { task in
            guard let closed = task.closed else { return false }
            return closed < cutoffDate
        }
        
        for task in tasksToArchive {
            task.state = .dead
        }
        save()
        logger.info("Archived \(tasksToArchive.count) completed tasks older than \(days) days")
    }
    
    // MARK: - Filtering and Searching
    
    /// Filter tasks by tags
    func tasks(in state: TaskItemState, withTags tags: [String]) -> [TaskItem] {
        if tags.isEmpty {
            return list(which: state)
        }
        
        return list(which: state).filter { task in
            task.tags.contains { tags.contains($0) }
        }
    }
    
    /// Search tasks by title
    func searchTasks(query: String) -> [TaskItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return allTasks
        }
        
        let lowercaseQuery = query.lowercased()
        return allTasks.filter { task in
            task.title.lowercased().contains(lowercaseQuery)
        }
    }
    
    // MARK: - Statistics
    
    /// Get task counts by state
    var taskCounts: [TaskItemState: Int] {
        var counts: [TaskItemState: Int] = [:]
        
        for state in TaskItemState.allCases {
            counts[state] = list(which: state).count
        }
        
        return counts
    }
    
    /// Get completion rate for a date range
    func completionRate(from startDate: Date, to endDate: Date) -> Double {
        let completedTasks = allTasks.filter { task in
            guard let closed = task.closed else { return false }
            return closed >= startDate && closed <= endDate
        }
        
        let totalTasks = allTasks.filter { task in
            task.created >= startDate && task.created <= endDate
        }
        
        guard totalTasks.count > 0 else { return 0.0 }
        return Double(completedTasks.count) / Double(totalTasks.count)
    }
    
    // MARK: - Data Persistence
    
    // MARK: - Data Management
    
    /// Load all tasks from the database and organize them into lists
    func loadData() {
        let descriptor = FetchDescriptor<TaskItem>()
        do {
            items = try modelContext.fetch(descriptor)
            ensureEveryItemHasAUniqueUuid()
            organizeLists()
            logger.debug("Loaded \(self.items.count) tasks from database")
        } catch {
            logger.error("Failed to load tasks: \(error)")
        }
    }
    
    /// Organize items into lists by state
    func organizeLists() {
        // Clear all lists
        for t in TaskItemState.allCases {
            lists[t]?.removeAll(keepingCapacity: true)
        }
        // Redistribute items
        for item in items {
            lists[item.state]?.append(item)
        }
        // Sort all lists
        for state in TaskItemState.allCases {
            sortList(state)
        }
    }
    
    /// Sort a specific list by its state's criteria
    private func sortList(_ state: TaskItemState) {
        lists[state]?.sort { task1, task2 in
            if state == .closed || state == .dead {
                return task1.changed > task2.changed // Most recent first
            } else {
                return task1.changed < task2.changed // Oldest first
            }
        }
    }
    
    /// Ensure every item has a unique UUID
    private func ensureEveryItemHasAUniqueUuid() {
        var allUuids: Set<UUID> = []
        for i in items {
            if allUuids.contains(i.uuid) {
                i.uuid = UUID()
            } else {
                allUuids.insert(i.uuid)
            }
        }
        assert(
            Set(items.map(\.uuid)).count == items.count,
            "Duplicate UUIDs: \(items.count - Set(items.map(\.uuid)).count)")
    }
    
    /// Save changes to persistent store
    func save() {
        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save context: \(error)")
        }
    }
    
    /// Refresh data from persistent store
    func refresh() {
        // SwiftData automatically refreshes, but we can trigger explicit refresh if needed
        // This is useful after background updates or external changes
    }
    
    // MARK: - Batch Operations
    
    /// Move multiple tasks to the same state
    func batchMove(_ tasks: [TaskItem], to state: TaskItemState) {
        for task in tasks {
            task.state = state
        }
        save()
    }
    
    // MARK: - Undo/Redo Operations
    
    /// Check if undo is available
    var canUndo: Bool {
        return modelContext.canUndo
    }
    
    /// Check if redo is available
    var canRedo: Bool {
        return modelContext.canRedo
    }
    
    /// Perform undo operation
    func undo() {
        modelContext.processPendingChanges()
        modelContext.undo()
        modelContext.processPendingChanges()
    }
    
    /// Perform redo operation
    func redo() {
        modelContext.processPendingChanges()
        modelContext.redo()
        modelContext.processPendingChanges()
    }
    
    /// Begin undo grouping
    func beginUndoGrouping() {
        modelContext.beginUndoGrouping()
    }
    
    /// End undo grouping
    func endUndoGrouping() {
        modelContext.endUndoGrouping()
    }
    
    /// Process pending changes
    func processPendingChanges() {
        modelContext.processPendingChanges()
    }
    
    /// Check if there are unsaved changes
    var hasChanges: Bool {
        return modelContext.hasChanges
    }
    
    // MARK: - Test Data Operations
    
    /// Create test data for development/testing
    func createTestData() {
        let lastWeek1 = TaskItem(title: "Last Week 1", state: .closed)
        let lastWeek2 = TaskItem(title: "Last Week 2", state: .closed)
        let lastMonth1 = TaskItem(title: "Last Month 1", state: .closed)
        let lastMonth2 = TaskItem(title: "Last Month 2", state: .closed)
        let older1 = TaskItem(title: "Older 1", state: .closed)
        let older2 = TaskItem(title: "Older 2", state: .closed)
        
        modelContext.insert(lastWeek1)
        modelContext.insert(lastWeek2)
        modelContext.insert(lastMonth1)
        modelContext.insert(lastMonth2)
        modelContext.insert(older1)
        modelContext.insert(older2)
        
        try? modelContext.save()
    }
    
    /// Clear all data (for testing)
    func clearAllData() {
        // Uncomment when needed for testing
        // try? modelContext.delete(model: TaskItem.self)
        // try? modelContext.save()
    }
    
    // MARK: - Attachment Operations
    
    /// Get due tasks for attachment processing
    func getDueTasks() -> [TaskItem]? {
        // Get all open tasks and filter them in memory since the predicate is complex
        let openTasks = list(which: .open)
        return openTasks.filter { task in
            guard let due = task.due else { return false }
            return due < Date()
        }
    }
    
    /// Get all tasks for attachment processing
    func getAllTasksForAttachments() -> [TaskItem]? {
        return try? modelContext.fetch(FetchDescriptor<TaskItem>())
    }
    
    /// Add tags to multiple tasks
    func batchAddTags(_ tags: [String], to tasks: [TaskItem]) {
        for task in tasks {
            let currentTags = Set(task.tags)
            let newTags = currentTags.union(tags)
            task.tags = Array(newTags)
        }
        save()
    }
    
    /// Remove tags from multiple tasks
    func batchRemoveTags(_ tags: [String], from tasks: [TaskItem]) {
        for task in tasks {
            let currentTags = Set(task.tags)
            let remainingTags = currentTags.subtracting(tags)
            task.tags = Array(remainingTags)
        }
        save()
    }
}

// MARK: - Test Helper

extension DataManager {
    static func testManager() -> DataManager {
        // Create in-memory model container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: TaskItem.self, configurations: config)
        return DataManager(modelContext: container.mainContext)
    }
}
