//
//  DataManager.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 14/01/2025.
//

import Foundation
import SwiftData
import SwiftUI
import os
import TipKit
import tdgCoreMain

/// Struct for import conflict resolution
public struct Choice {
    let existing: TaskItem
    let new: TaskItem
}

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: "DataManager"
)

@MainActor
@Observable
public final class DataManager {

    let modelContext: ModelContext
    let timeProvider: TimeProvider
    var priorityUpdater: PriorityUpdater?
    var itemSelector: ItemSelector?
    var dataIssueReporter: DataIssueReporter?
    var jsonExportDoc: JSONWriteOnlyDoc? {
        return JSONWriteOnlyDoc(content: allTasks)
    }
    
    // Observable undo/redo state
    var undoAvailable: Bool = false
    var redoAvailable: Bool = false

    init(modelContext: ModelContext, timeProvider: TimeProvider) {
        self.modelContext = modelContext
        self.timeProvider = timeProvider
        
        // Set up undo manager notifications
        setupUndoNotifications()
        updateUndoRedoState()
    }

    // MARK: - Data Access

    /// Get all tasks for a specific state
    func list(which state: TaskItemState) -> [TaskItem] {
        // Fetch all tasks and filter in memory (predicate doesn't support enum captures)
        let filtered = allTasks.filter { $0.state == state }
        
        // Sort by changed date
        if state == .closed || state == .dead {
            return filtered.sorted { $0.changed > $1.changed }
        }
        return filtered.sorted { $0.changed < $1.changed }
    }

    /// Get all tasks
    var allTasks: [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>()
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("Failed to fetch all tasks: \(error)")
            return []
        }
    }

    /// Get current list based on UI state (delegates to TaskManagerViewModel)
    var currentList: [TaskItem] {
        // This will be overridden by TaskManagerViewModel to provide the actual current list
        return []
    }

    /// Get all active tags across all tasks
    var activeTags: Set<String> {
        var result = Set<String>()
        for t in allTasks where !t.tags.isEmpty && t.isActive {
            result.formUnion(t.tags)
        }
        result.formUnion(["work", "private"])
        return result
    }

    // MARK: - Task Operations

    /// Find a task by UUID string
    func findTask(withUuidString uuidString: String) -> TaskItem? {
        // Convert string to UUID for comparison with stored uuid property
        guard let searchUuid = UUID(uuidString: uuidString) else {
            logger.error("Invalid UUID string: \(uuidString)")
            return nil
        }
        
        // Search by the actual stored uuid property (predicates can't access computed 'id')
        let predicate = #Predicate<TaskItem> { task in
            task.uuid == searchUuid
        }
        let descriptor = FetchDescriptor<TaskItem>(predicate: predicate)
        
        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
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

        // Update task state - SwiftData will autosave, no need to call save()
        task.state = state
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
            priorityUpdater?.updatePriorities(prioTasks: list(which: .priority))
        }
    }

    /// Create a new task
    @discardableResult func createTask(title: String, state: TaskItemState = .open) -> TaskItem {
        let task = TaskItem(title: title, state: state)
        addExistingTask(task)
        return task
    }

    /// Add an existing task to the data manager
    func addExistingTask(_ task: TaskItem) {
        modelContext.insert(task)
        // SwiftData will autosave
    }

    /// Add a new task with specified parameters
    @discardableResult func addItem(
        title: String = emptyTaskTitle,
        details: String = emptyTaskDetails,
        changedDate: Date? = nil,
        state: TaskItemState = .open
    ) -> TaskItem {
        let finalChangedDate = changedDate ?? timeProvider.now
        let newItem = TaskItem(title: title, details: details, changedDate: finalChangedDate, state: state)
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
        // Delete comments first
        for c in task.comments ?? [] {
            modelContext.delete(c)
        }

        // Delete from database - SwiftData will autosave
        modelContext.delete(task)
    }

    /// Delete a task with undo grouping
    func delete(task: TaskItem) {
        deleteTask(task)
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
                let newComment = Comment(text: comment.text, taskItem: newTask, icon: comment.icon, state: comment.state)
                newTask.comments?.append(newComment)
            }
        }

        modelContext.insert(newTask)
        // SwiftData will autosave
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
        // SwiftData will autosave
    }

//    /// Touch a task (update its changed date)
//    func touch(task: TaskItem) {
//        task.touch()
//        save()
//    }
//
//    /// Touch a task and update undo status
//    func touchAndUpdateUndoStatus(task: TaskItem) {
//        touch(task: task)
//        updateUndoRedoStatus()
//    }
    
    /// Touch a task with a description and update undo status
    func touchWithDescriptionAndUpdateUndoStatus(task: TaskItem, description: String) {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedDescription.isEmpty {
            // Use the provided description
            task.setChangedDate(.now)
            task.addComment(text: trimmedDescription, icon: task.state.imageName, state: task.state)
        } else {
            // Use default touch message for empty/whitespace descriptions
            task.setChangedDate(.now)
            task.addComment(text: "You 'touched' this task.", icon: task.state.imageName, state: task.state)
        }
        
        updateUndoRedoStatus()
    }

    /// Remove a task from the data manager
    func remove(task: TaskItem) {
        deleteTask(task)
    }

    /// Remove a task by ID
    func removeItem(withID: String) {
        if let item = allTasks.first(where: { $0.id == withID }) {
            remove(task: item)
        }
    }

    /// Kill old tasks that are older than the specified number of days
    @discardableResult func killOldTasks(expireAfter: Int? = nil, preferences: CloudPreferences) -> Int {
        var result = 0
        let expiryDays = expireAfter ?? preferences.expiryAfter
        let expireData = timeProvider.getDate(daysPrior: expiryDays)
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
        let lastWeek1 = TaskItem(title: "3 days ago", changedDate: timeProvider.getDate(daysPrior: 3))
        let lastWeek2 = TaskItem(title: "5 days ago", changedDate: timeProvider.getDate(daysPrior: 5))
        let lastMonth1 = TaskItem(title: "11 days ago", changedDate: timeProvider.getDate(daysPrior: 11))
        let lastMonth2 = TaskItem(title: "22 days ago", changedDate: timeProvider.getDate(daysPrior: 22))
        let older1 = TaskItem(title: "31 days ago", changedDate: timeProvider.getDate(daysPrior: 31))
        let older2 = TaskItem(title: "101 days ago", changedDate: timeProvider.getDate(daysPrior: 101))

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
        changedDate: Date? = nil,
        state: TaskItemState = .open
    ) -> TaskItem {
        let finalChangedDate = changedDate ?? timeProvider.now
        let newItem = addItem(title: title, details: details, changedDate: finalChangedDate, state: state)
        // Find the saved item in the database to ensure we're selecting the correct object
        guard let savedItem = findTask(withUuidString: newItem.uuid.uuidString) else {
            return newItem
        }
        return savedItem
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
        let cutoffDate = timeProvider.date(byAdding: .day, value: -days, to: timeProvider.now) ?? timeProvider.now

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
        do {
            ensureEveryItemHasAUniqueUuid()
            
            // Clean up unchanged items after loading
            cleanupUnchangedItems()
            
            //logger.debug("Loaded \(self.allTasks.count) tasks from database")
        } catch {
            logger.error("Failed to load tasks: \(error)")
            reportDatabaseError(.containerCreationFailed(underlyingError: error))
        }
    }

    /// Clean up unchanged items that were persisted but should be removed
    private func cleanupUnchangedItems() {
        let unchangedItems = allTasks.filter { $0.isUnchanged }
        if !unchangedItems.isEmpty {
            logger.info("Cleaning up \(unchangedItems.count) unchanged items")
            for item in unchangedItems {
                deleteTask(item)
            }
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

            logger.info("fetched \(fetchedItems.count) tasks from central store")
            
            // Clean up unchanged items after merging
            cleanupUnchangedItems()
            
            ensureEveryItemHasAUniqueUuid()

        } catch {
            logger.error("Fetch failed: \(error)")
            // For CloudKit sync failures, use the appropriate error type
            if error.localizedDescription.lowercased().contains("cloudkit") || 
               error.localizedDescription.lowercased().contains("sync") {
                reportDatabaseError(.cloudKitSyncFailed(underlyingError: error))
            } else {
                reportDatabaseError(.containerCreationFailed(underlyingError: error))
            }
        }
    }


    /// Ensure every item has a unique UUID
    private func ensureEveryItemHasAUniqueUuid() {
        let tasks = allTasks
        var allUuids: Set<UUID> = []
        for i in tasks {
            if allUuids.contains(i.uuid) {
                i.uuid = UUID()
            } else {
                allUuids.insert(i.uuid)
            }
        }
        assert(
            Set(tasks.map(\.uuid)).count == tasks.count,
            "Duplicate UUIDs: \(tasks.count - Set(tasks.map(\.uuid)).count)")
    }

    /// Save changes to the database
    func save() {
        do {
            try modelContext.save()
            logger.debug("Successfully saved changes to database")
        } catch {
            logger.error("Failed to save changes: \(error)")
            reportDatabaseError(.containerCreationFailed(underlyingError: error))
        }
    }
    
    /// Report a database error to the user interface
    private func reportDatabaseError(_ error: DatabaseError) {
        dataIssueReporter?.reportDatabaseError(error)
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

    /// Set up notifications to listen to undo manager changes
    private func setupUndoNotifications() {
        guard let undoManager = modelContext.undoManager else { return }
        
        NotificationCenter.default.addObserver(
            forName: .NSUndoManagerDidUndoChange,
            object: undoManager,
            queue: .main
        ) { [weak self] _ in
            self?.updateUndoRedoState()
        }
        
        NotificationCenter.default.addObserver(
            forName: .NSUndoManagerDidRedoChange,
            object: undoManager,
            queue: .main
        ) { [weak self] _ in
            self?.updateUndoRedoState()
        }
        
        NotificationCenter.default.addObserver(
            forName: .NSUndoManagerDidOpenUndoGroup,
            object: undoManager,
            queue: .main
        ) { [weak self] _ in
            self?.updateUndoRedoState()
        }
        
        NotificationCenter.default.addObserver(
            forName: .NSUndoManagerDidCloseUndoGroup,
            object: undoManager,
            queue: .main
        ) { [weak self] _ in
            self?.updateUndoRedoState()
        }
    }
    
    /// Update the observable undo/redo state
    private func updateUndoRedoState() {
        undoAvailable = modelContext.undoManager?.canUndo ?? false
        redoAvailable = modelContext.undoManager?.canRedo ?? false
    }

    /// Undo the last operation
    func undo() {
        modelContext.undoManager?.undo()
        updateUndoRedoState()
    }

    /// Redo the last undone operation
    func redo() {
        modelContext.undoManager?.redo()
        updateUndoRedoState()
    }

    /// Check if undo is available
    var canUndo: Bool {
        return undoAvailable
    }

    /// Check if redo is available
    var canRedo: Bool {
        return redoAvailable
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
            let lowercaseTags = tags.map { $0.lowercased() }
            let newTags = currentTags.union(lowercaseTags)
            task.tags = Array(newTags)
        }
        save()
    }

    /// Remove tags from multiple tasks
    func batchRemoveTags(_ tags: [String], from tasks: [TaskItem]) {
        for task in tasks {
            let currentTags = Set(task.tags)
            let lowercaseTags = tags.map { $0.lowercased() }
            let remainingTags = currentTags.subtracting(lowercaseTags)
            task.tags = Array(remainingTags)
        }
        save()
    }

    // MARK: - Tag Management

    /// Get all tags from tasks
    var allTags: Set<String> {
        var result = Set<String>()
        for task in allTasks where !task.tags.isEmpty {
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
        let lowercaseTo = to.lowercased()
        for item in allTasks {
            item.tags = item.tags.map { $0 == from ? lowercaseTo : $0 }
        }
        save()
    }

    /// Delete a specific tag from all tasks
    func delete(tag: String) {
        if tag.isEmpty {
            return
        }
        for item in allTasks {
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
            let data = try encoder.encode(allTasks)

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
            Label("Undo", systemImage: imgUndo)
                .accessibilityIdentifier("undoButton")
                .help("undo an action")
        }
        .disabled(!canUndo)
        .opacity(canUndo ? 1.0 : 0.5) // Make disabled buttons visible but dimmed
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
            Label("Redo", systemImage: imgRedo)
                .accessibilityIdentifier("redoButton")
                .help("redo an action")
        }
        .disabled(!canRedo)
        .opacity(canRedo ? 1.0 : 0.5) // Make disabled buttons visible but dimmed
        .keyboardShortcut("Z", modifiers: [.command, .shift])
    }



    /// Close button for task items
    func closeButton(item: TaskItem) -> some View {
        Button(action: { [self] in
            moveWithPriorityTracking(task: item, to: .closed)
        }) {
            Label("Close", systemImage: imgClosed).foregroundColor(TaskItemState.closed.color)
        }
        .help("Close the task")
        .accessibilityIdentifier("closeButton")
        .disabled(!item.canBeClosed)
    }

    /// Kill button for task items
    func killButton(item: TaskItem) -> some View {
        Button(action: { [self] in
            moveWithPriorityTracking(task: item, to: .dead)
        }) {
            Label("Kill", systemImage: imgGraveyard).foregroundColor(TaskItemState.dead.color)
                
        }
        .help("Move the task to the Graveyard")
        .accessibilityIdentifier("killButton")
        .disabled(!item.canBeClosed)
    }

    /// Open button for task items
    func openButton(item: TaskItem) -> some View {
        Button(action: { [self] in
            moveWithPriorityTracking(task: item, to: .open)
        }) {
            Label("Open", systemImage: imgOpen).foregroundColor(TaskItemState.open.color)
                
        }
        .help("Open this task again")
        .accessibilityIdentifier("openButton")
        .disabled(!item.canBeMovedToOpen)
    }

    /// Wait for response button for task items
    func waitForResponseButton(item: TaskItem) -> some View {
        Button(action: { [self] in
            moveWithPriorityTracking(task: item, to: .pendingResponse)
        }) {
            Label("Pending a Response", systemImage: imgPendingResponse).foregroundColor(TaskItemState.pendingResponse.color)
                .help(
                    "Mark as Pending Response. That is the state for a task that you completed, but you are waiting for a response, acknowledgement or similar."
                )
        }
        .accessibilityIdentifier("pendingResponseButton")
        .disabled(!item.canBeMovedToPendingResponse)
    }

    /// Priority button for task items
    func priorityButton(item: TaskItem) -> some View {
        Button(action: { [self] in
            moveWithPriorityTracking(task: item, to: .priority)
        }) {
            Image(systemName: imgPriority).foregroundColor(TaskItemState.priority.color)
                .frame(width: 8, height: 8)
                .help("Make this task a priority for today")
        }
        .accessibilityIdentifier("prioritiseButton")
        .disabled(!item.canBeMadePriority)
        .popoverTip(PriorityTip())
    }

    /// Delete button for task items
    func deleteButton(item: TaskItem, uiState: UIStateManager) -> some View {
        Button(
            role: .destructive,
            action: { [self] in
                withAnimation {
                    deleteWithUIUpdate(task: item, uiState: uiState)
                }
            }
        ) {
            Label("Delete", systemImage: "trash")
                .help("Delete this task for good.")
        }
        .accessibilityIdentifier("deleteButton")
        .disabled(!item.canBeDeleted)
    }
    
    /// Touch button with description prompt for task items
    func touchWithDescriptionButton(item: TaskItem, presentAlert: Binding<Bool>, description: Binding<String>) -> some View {
        Button(action: {
            presentAlert.wrappedValue = true
        }) {
            Label("Touch", systemImage:imgTouch)
                .help("Touch this task and add a description of what was done")
        }
        .accessibilityIdentifier("touchWithDescriptionButton")
        .disabled(!item.canBeTouched)
        .alert("What did you do?", isPresented: presentAlert) {
            TextField("Description of what was done", text: description)
            Button("Cancel", role: .cancel) { }
            Button("Touch") {
                self.touchWithDescriptionAndUpdateUndoStatus(task: item, description: description.wrappedValue)
                description.wrappedValue = ""
            }
        } message: {
            Text("Please provide a short description of what you accomplished with this task")
        }
    }

    // MARK: - Attachment Management

    /// Get tasks with purgeable attachments at a given date
    func purgeableItems(at date: Date = Date()) -> [TaskItem] {
        let dueTasks = try? modelContext.fetch(
            FetchDescriptor<TaskItem>(
                predicate: #Predicate { task in
                    task.attachments?.contains {
                        !$0.isPurged && $0.nextPurgePrompt != nil && $0.nextPurgePrompt! <= date
                    } ?? false
                })
        )
        return dueTasks ?? []
    }

    /// Calculate total purgeable stored bytes for all tasks at a given date
    func purgeableStoredBytesAll(at date: Date = Date()) -> Int {
        purgeableItems().reduce(0) { $0 + $1.purgeableStoredBytes(at: date) }
    }

    /// Calculate total stored bytes for all tasks
    func totalStoredBytesAll() -> Int {
        (try? modelContext.fetch(FetchDescriptor<TaskItem>()))?
            .reduce(0) { $0 + $1.totalStoredBytes } ?? 0
    }

    /// Calculate total original bytes for all tasks
    func totalOriginalBytesAll() -> Int {
        (try? modelContext.fetch(FetchDescriptor<TaskItem>()))?
            .reduce(0) { $0 + $1.totalOriginalBytes } ?? 0
    }
}


extension DataManager :  NewItemProducer {
    public func removeItem(_ item: TaskItem) {
        if (item.isUnchanged) {
            debugPrint("is unchanged")
            deleteTask(item)
        } else {
            debugPrint("it was changed")
        }
    }

    public func produceNewItem() -> TaskItem? {
        let result = TaskItem()
        addExistingTask(result)
        return result
    }
}


