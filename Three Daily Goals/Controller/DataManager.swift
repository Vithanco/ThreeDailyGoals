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

/// Struct for import conflict resolution
struct Choice {
    let existing: TaskItem
    let new: TaskItem
}

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: "DataManager"
)

@MainActor
@Observable
final class DataManager {
    
    let modelContext: Storage
    var priorityUpdater: PriorityUpdater?
    var itemSelector: ItemSelector?
    
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
    
    /// Get current list based on UI state (delegates to TaskManagerViewModel)
    var currentList: [TaskItem] {
        // This will be overridden by TaskManagerViewModel to provide the actual current list
        return []
    }
    
    /// Get all active tags across all tasks
    var activeTags: Set<String> {
        var result = Set<String>()
        for t in items where !t.tags.isEmpty && t.isActive {
            result.formUnion(t.tags)
        }
        result.formUnion(["work", "private"])
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
    
    /// Move a task to a different state with priority tracking
    func moveWithPriorityTracking(task: TaskItem, to state: TaskItemState) {
        if task.state == state {
            return  // nothing to be done
        }
        let moveFromPriority = task.state == .priority
        
        // Update the task state
        move(task: task, to: state)
        
        // Did it touch priorities (in or out)? If so, update priorities
        if state == .priority || moveFromPriority {
            priorityUpdater?.updatePriorities()
        }
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
    
    /// Add a new task with specified parameters
    @discardableResult func addItem(
        title: String = emptyTaskTitle,
        details: String = emptyTaskDetails,
        changedDate: Date = Date.now,
        state: TaskItemState = .open
    ) -> TaskItem {
        let newItem = TaskItem(title: title, details: details, changedDate: changedDate, state: state)
        addExistingTask(newItem)
        return newItem
    }
    
    /// Add an existing task item
    func addItem(item: TaskItem) {
        if item.isEmpty {
            return
        }
        addExistingTask(item)
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
    
    /// Delete a task with undo grouping
    func delete(task: TaskItem) {
        beginUndoGrouping()
        deleteTask(task)
        endUndoGrouping()
    }
    
    /// Delete a task with undo grouping and UI updates
    func deleteWithUIUpdate(task: TaskItem, uiState: UIStateManager) {
        delete(task: task)
        updateUndoRedoStatus()
        uiState.selectedItem = list(which: uiState.whichList).first
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
    
    /// Touch a task (update its changed date)
    func touch(task: TaskItem) {
        task.touch()
        save()
    }
    
    /// Touch a task and update undo status
    func touchAndUpdateUndoStatus(task: TaskItem) {
        touch(task: task)
        updateUndoRedoStatus()
    }
    
    /// Remove a task from the data manager
    func remove(task: TaskItem) {
        items.removeObject(task)
        lists[task.state]?.removeObject(task)
        deleteTask(task)
    }
    
    /// Remove a task by ID
    func removeItem(withID: String) {
        if let item = items.first(where: { $0.id == withID }) {
            remove(task: item)
        }
    }
    
    /// Kill old tasks that are older than the specified number of days
    @discardableResult func killOldTasks(expireAfter: Int? = nil, preferences: CloudPreferences) -> Int {
        var result = 0
        let expiryDays = expireAfter ?? preferences.expiryAfter
        let expireData = getDate(daysPrior: expiryDays)
        result += killOldTasks(expiryDate: expireData, whichList: .open)
        result += killOldTasks(expiryDate: expireData, whichList: .priority)
        result += killOldTasks(expiryDate: expireData, whichList: .pendingResponse)
        logger.info("killed \(result) tasks")
        return result
    }
    
    /// Kill old tasks in a specific list that are older than the expiry date
    func killOldTasks(expiryDate: Date, whichList: TaskItemState) -> Int {
        let theList = list(which: whichList)
        var result = 0
        for task in theList where task.changed < expiryDate {
            move(task: task, to: .dead)
            result += 1
        }
        return result
    }
    
    /// Create sample data for testing/development
    func createSampleData() {
        let lastWeek1 = TaskItem(title: "3 days ago", changedDate: getDate(daysPrior: 3))
        let lastWeek2 = TaskItem(title: "5 days ago", changedDate: getDate(daysPrior: 5))
        let lastMonth1 = TaskItem(title: "11 days ago", changedDate: getDate(daysPrior: 11))
        let lastMonth2 = TaskItem(title: "22 days ago", changedDate: getDate(daysPrior: 22))
        let older1 = TaskItem(title: "31 days ago", changedDate: getDate(daysPrior: 31))
        let older2 = TaskItem(title: "101 days ago", changedDate: getDate(daysPrior: 101))
        
        move(task: lastWeek1, to: .priority)
        createTask(title: lastWeek1.title, state: lastWeek1.state)
        createTask(title: lastWeek2.title, state: lastWeek2.state)
        createTask(title: lastMonth1.title, state: lastMonth1.state)
        createTask(title: lastMonth2.title, state: lastMonth2.state)
        createTask(title: older1.title, state: older1.state)
        createTask(title: older2.title, state: older2.state)
    }
    
    /// Add samples and merge data
    func addSamples() {
        createSampleData()
        mergeDataFromCentralStorage()
    }
    
    /// Add item and return the saved version from database
    func addAndFindItem(
        title: String = emptyTaskTitle,
        details: String = emptyTaskDetails,
        changedDate: Date = Date.now,
        state: TaskItemState = .open
    ) -> TaskItem {
        let newItem = addItem(title: title, details: details, changedDate: changedDate, state: state)
        // Find the saved item in the database to ensure we're selecting the correct object
        if let savedItem = findTask(withUuidString: newItem.uuid.uuidString) {
            return savedItem
        } else {
            return newItem
        }
    }
    
    /// Call fetch to update data
    func callFetch() {
        mergeDataFromCentralStorage()
    }
    
    /// Add a new task and select it
    @discardableResult func addAndSelect(
        title: String = emptyTaskTitle,
        details: String = emptyTaskDetails,
        changedDate: Date = Date.now,
        state: TaskItemState = .open
    ) -> TaskItem {
        let item = addAndFindItem(title: title, details: details, changedDate: changedDate, state: state)
        itemSelector?.select(item)
        return item
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
    
    /// Merge data from central storage (CloudKit)
    func mergeDataFromCentralStorage() {
        processPendingChanges()
        do {
            let descriptor = FetchDescriptor<TaskItem>(sortBy: [
                SortDescriptor(\.changed, order: .forward)
            ])
            let fetchedItems = try modelContext.fetch(descriptor)
            let (added, updated) = mergeItems(fetchedItems)

            logger.info(
                "fetched \(fetchedItems.count) tasks from central store, added \(added), updated \(updated)")
            // Organize lists after merging
            organizeLists()
            ensureEveryItemHasAUniqueUuid()

        } catch {
            logger.error("Fetch failed: \(error)")
        }
    }
    
    /// Merge fetched items with existing items
    private func mergeItems(_ fetchedItems: [TaskItem]) -> (Int, Int) {
        var seenIDs = Set<UUID>()
        let adjustedItems = fetchedItems.map { item -> TaskItem in
            if seenIDs.contains(item.uuid) {
                let newItem = item
                newItem.uuid = UUID()
                return newItem
            }
            seenIDs.insert(item.uuid)
            return item
        }
        
        var addedCount = 0
        var updatedCount = 0

        // Create a dictionary of existing items by ID for quick lookup
        var existingItemsById = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })

        for fetchedItem in adjustedItems {
            if let existingItem = existingItemsById[fetchedItem.id] {
                // Item exists, check if it needs updating
                if fetchedItem.changed > existingItem.changed {
                    existingItem.updateFrom(fetchedItem)
                    updatedCount = updatedCount + 1
                }
            } else {
                // New item, add it
                items.append(fetchedItem)
                existingItemsById[fetchedItem.id] = fetchedItem
                addedCount = addedCount + 1
            }
        }
        
        return (addedCount, updatedCount)
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
    func sortList(_ state: TaskItemState) {
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
    
    /// Save changes to the database
    func save() {
        do {
            try modelContext.save()
            logger.debug("Successfully saved changes to database")
        } catch {
            logger.error("Failed to save changes: \(error)")
        }
    }
    
    /// Refresh data from persistent store
    func refresh() {
        // SwiftData automatically refreshes, but we can trigger explicit refresh if needed
        // This is useful after background updates or external changes
    }
    
    // MARK: - Undo Management
    
    /// Check if undo manager is available
    var hasUndoManager: Bool {
        return modelContext.undoManager != nil
    }
    
    /// Begin undo grouping
    func beginUndoGrouping() {
        modelContext.undoManager?.beginUndoGrouping()
    }
    
    /// End undo grouping
    func endUndoGrouping() {
        modelContext.undoManager?.endUndoGrouping()
    }
    
    /// Undo the last operation
    func undo() {
        modelContext.undoManager?.undo()
    }
    
    /// Redo the last undone operation
    func redo() {
        modelContext.undoManager?.redo()
    }
    
    /// Check if undo is available
    var canUndo: Bool {
        return modelContext.undoManager?.canUndo ?? false
    }
    
    /// Check if redo is available
    var canRedo: Bool {
        return modelContext.undoManager?.canRedo ?? false
    }
    
    /// Process pending changes
    func processPendingChanges() {
        modelContext.processPendingChanges()
    }
    
    /// Update undo/redo status (data only)
    func updateUndoRedoStatus() {
        processPendingChanges()
        processPendingChanges()
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
    
    // MARK: - Tag Management
    
    /// Get all tags from tasks
    var allTags: Set<String> {
        var result = Set<String>()
        for task in items where !task.tags.isEmpty {
            result.formUnion(task.tags)
        }
        result.formUnion(["work", "private"])
        return result
    }
    
    /// Get statistics for a specific tag across all states
    func statsForTags(tag: String) -> [TaskItemState: Int] {
        var result: [TaskItemState: Int] = [:]
        for state in TaskItemState.allCases {
            result[state] = statsForTags(tag: tag, which: state)
        }
        return result
    }
    
    /// Get count of tasks with a specific tag in a specific state
    func statsForTags(tag: String, which state: TaskItemState) -> Int {
        let list = self.list(which: state)
        var result = 0
        for item in list where item.tags.contains(tag) {
            result += 1
        }
        return result
    }
    
    /// Exchange one tag for another across all tasks
    func exchangeTag(from: String, to: String) {
        for item in items {
            item.tags = item.tags.map { $0 == from ? to : $0 }
        }
        save()
    }
    
    /// Delete a specific tag from all tasks
    func delete(tag: String) {
        if tag.isEmpty {
            return
        }
        for item in items {
            item.tags = item.tags.filter { $0 != tag }
        }
        save()
    }
    
    // MARK: - Import/Export
    
    /// Export tasks to JSON file
    func exportTasks(url: URL, uiState: UIStateManager) {
        do {
            // Create an instance of JSONEncoder
            let encoder = JSONEncoder()
            // Convert your array into JSON data
            let data = try encoder.encode(items)

            // Write the data to the file
            try data.write(to: url)
            uiState.infoMessage = "The tasks were exported and saved as JSON to \(url)"
        } catch {
            uiState.infoMessage = "The tasks weren't exported because: \(error)"
        }
        uiState.showInfoMessage = true
    }

    /// Import tasks from JSON file
    func importTasks(url: URL, uiState: UIStateManager) {
        var choices = [Choice]()
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode([TaskItem].self, from: data)
            beginUndoGrouping()
            for item in jsonData {
                if let existing = findTask(withUuidString: item.id) {
                    if !deepEqual(existing, item) {
                        choices.append(Choice(existing: existing, new: item))
                    }
                } else {
                    addItem(item: item)
                }
            }
            uiState.selectDuringImport = choices
            uiState.showSelectDuringImportDialog = true
            uiState.infoMessage = "\(jsonData.count) tasks were imported."
        } catch {
            uiState.infoMessage = "The tasks weren't imported because :\(error)"
        }

        endUndoGrouping()
        uiState.showInfoMessage = true
    }
    
    // MARK: - Command Buttons
    
    /// Undo button for app commands
    var undoButton: some View {
        Button(action: { [self] in
            withAnimation {
                undo()
                callFetch()
            }
        }) {
            Label("Undo", systemImage: "arrow.uturn.backward")
                .accessibilityIdentifier("undoButton")
                .help("undo an action")
        }
        .disabled(!canUndo)
        .keyboardShortcut("z", modifiers: [.command])
    }
    
    /// Redo button for app commands
    var redoButton: some View {
        Button(action: { [self] in
            withAnimation {
                redo()
                callFetch()
            }
        }) {
            Label("Redo", systemImage: "arrow.uturn.forward")
                .accessibilityIdentifier("redoButton")
                .help("redo an action")
        }
        .disabled(!canRedo)
        .keyboardShortcut("Z", modifiers: [.command, .shift])
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
