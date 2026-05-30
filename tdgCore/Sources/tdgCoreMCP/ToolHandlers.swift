import Foundation
import MCP
import SwiftData
import tdgCoreMain
import tdgCoreWidget

@MainActor
public struct MCPToolRouter {
    let container: ModelContainer
    let timeProvider: TimeProvider

    private var shortIdPrefix: String {
        let preferences = CloudPreferences(testData: false, timeProvider: timeProvider)
        return preferences.shortIdPrefix
    }

    public init(container: ModelContainer, timeProvider: TimeProvider = RealTimeProvider()) {
        self.container = container
        self.timeProvider = timeProvider
    }

    public func handle(name: String, arguments: [String: Value]?) async throws -> CallTool.Result {
        switch name {
        case "find_tasks":
            return try await handleFindTasks(arguments)
        case "get_task":
            return try await handleGetTask(arguments)
        case "get_statistics":
            return try await handleGetStatistics(arguments)
        case "get_compass_check_status":
            return handleGetCompassCheckStatus()
        case "get_preferences":
            return handleGetPreferences()
        case "list_tags":
            return try await handleListTags()
        case "create_task":
            return try await handleCreateTask(arguments)
        case "update_task":
            return try await handleUpdateTask(arguments)
        case "manage_tags":
            return try await handleManageTags(arguments)
        default:
            return CallTool.Result(content: [.text("Error: Unknown tool '\(name)'")], isError: true)
        }
    }

    // MARK: - Task Resolution

    /// Outcome of resolving a task from tool arguments: either the task, or a
    /// ready-to-return error response. Not `Swift.Result` because `CallTool.Result`
    /// does not conform to `Error`.
    private enum TaskResolution {
        case success(TaskItem)
        case failure(CallTool.Result)
    }

    private func resolveTask(
        from arguments: [String: Value]?,
        in context: ModelContext
    ) throws -> TaskResolution {
        guard let id = arguments?.stringValue("id") else {
            return .failure(
                CallTool.Result(
                    content: [.text("Error: 'id' parameter is required")], isError: true))
        }

        guard let parsed = ShortIdHelper.parseTaskId(id) else {
            return .failure(
                CallTool.Result(
                    content: [
                        .text(
                            "Error: Invalid task ID format '\(id)'. Provide a full UUID or short ID (e.g. TDG-A1B2C3D4)"
                        )
                    ],
                    isError: true))
        }

        let descriptor = FetchDescriptor<TaskItem>()
        let allTasks = try context.fetch(descriptor)

        switch parsed {
        case .fullUUID(let uuid):
            guard let task = allTasks.first(where: { $0.uuid == uuid }) else {
                return .failure(
                    CallTool.Result(
                        content: [.text("Error: No task found with id '\(id)'")], isError: true))
            }
            return .success(task)
        case .shortHex(let hex):
            let matches = allTasks.filter {
                $0.uuid.uuidString.prefix(8).caseInsensitiveCompare(hex) == .orderedSame
            }
            switch matches.count {
            case 0:
                return .failure(
                    CallTool.Result(
                        content: [.text("Error: No task found with short ID '\(id)'")], isError: true))
            case 1:
                return .success(matches[0])
            default:
                return .failure(
                    CallTool.Result(
                        content: [
                            .text(
                                "Error: Short ID '\(id)' matches \(matches.count) tasks. Use the full UUID to disambiguate."
                            )
                        ],
                        isError: true))
            }
        }
    }

    // MARK: - Read Handlers

    private func handleFindTasks(_ arguments: [String: Value]?) async throws -> CallTool.Result {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<TaskItem>()
        let allTasks = try context.fetch(descriptor)

        var filtered = allTasks

        if let stateStr = arguments?.stringValue("state") {
            guard let state = parseState(stateStr) else {
                return CallTool.Result(
                    content: [
                        .text(
                            "Error: Invalid state '\(stateStr)'. Valid: open, priority, pendingResponse, closed, dead")
                    ],
                    isError: true)
            }
            filtered = filtered.filter { $0.state == state }
        }

        if let query = arguments?.stringValue("query"), !query.isEmpty {
            let q = query.lowercased()
            filtered = filtered.filter { task in
                task.title.lowercased().contains(q)
                    || task.details.lowercased().contains(q)
                    || task.tags.contains { $0.lowercased().contains(q) }
            }
        }

        if let tags = arguments?.stringArrayValue("tags") {
            let normalizedTags = tags.map { $0.lowercased() }
            filtered = filtered.filter { task in
                normalizedTags.allSatisfy { tag in task.tags.contains(tag) }
            }
        }

        if let days = arguments?.intValue("due_within_days") {
            let now = timeProvider.now
            let cutoff = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
            filtered = filtered.filter { task in
                guard let due = task.dueDate else { return false }
                return due <= cutoff && due >= now
            }
        }

        filtered.sort { $0.changed < $1.changed }

        let prefix = shortIdPrefix
        let summaries = filtered.map { serializeSummary($0, prefix: prefix) }
        let json = toJSON(summaries)
        return CallTool.Result(content: [.text(json)])
    }

    private func handleGetTask(_ arguments: [String: Value]?) async throws -> CallTool.Result {
        let context = ModelContext(container)
        switch try resolveTask(from: arguments, in: context) {
        case .failure(let error): return error
        case .success(let task):
            let detail = serializeDetail(task, prefix: shortIdPrefix)
            return CallTool.Result(content: [.text(toJSON(detail))])
        }
    }

    private func handleGetStatistics(_ arguments: [String: Value]?) async throws -> CallTool.Result {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<TaskItem>()
        var allTasks = try context.fetch(descriptor)

        if let tag = arguments?.stringValue("tag") {
            let normalizedTag = tag.lowercased()
            allTasks = allTasks.filter { $0.tags.contains(normalizedTag) }
        }

        var counts: [String: Int] = [:]
        for state in TaskItemState.allCases {
            counts[state.description] = allTasks.filter { $0.state == state }.count
        }
        counts["total"] = allTasks.count

        var result: [String: Any] = ["counts": counts]
        if let tag = arguments?.stringValue("tag") {
            result["filtered_by_tag"] = tag
        }

        return CallTool.Result(content: [.text(toJSON(result))])
    }

    private func handleGetCompassCheckStatus() -> CallTool.Result {
        let preferences = CloudPreferences(testData: false, timeProvider: timeProvider)
        let result: [String: Any] = [
            "current_streak": preferences.daysOfCompassCheck,
            "longest_streak": preferences.longestStreak,
            "last_check": formatDate(preferences.lastCompassCheck) as Any,
            "done_today": preferences.didCompassCheckToday,
            "streak_active": preferences.isStreakActive,
            "note": "Data is read from iCloud key-value store and may be stale in CLI context",
        ]
        return CallTool.Result(content: [.text(toJSON(result))])
    }

    private func handleGetPreferences() -> CallTool.Result {
        let preferences = CloudPreferences(testData: false, timeProvider: timeProvider)
        let result: [String: Any] = [
            "expiry_after_days": preferences.expiryAfter,
            "compass_check_time": formatDate(preferences.compassCheckTime) as Any,
            "short_id_prefix": preferences.shortIdPrefix,
            "note": "Data is read from iCloud key-value store and may be stale in CLI context",
        ]
        return CallTool.Result(content: [.text(toJSON(result))])
    }

    private func handleListTags() async throws -> CallTool.Result {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<TaskItem>()
        let allTasks = try context.fetch(descriptor)

        let activeTasks = allTasks.filter { [.open, .priority, .pendingResponse].contains($0.state) }
        var tagCounts: [String: Int] = [:]
        for task in activeTasks {
            for tag in task.tags {
                tagCounts[tag, default: 0] += 1
            }
        }

        let sorted = tagCounts.sorted { $0.value > $1.value }
        let result = sorted.map { ["tag": $0.key, "active_count": $0.value] as [String: Any] }
        return CallTool.Result(content: [.text(toJSON(result))])
    }

    // MARK: - Write Handlers

    private func handleCreateTask(_ arguments: [String: Value]?) async throws -> CallTool.Result {
        guard let title = arguments?.stringValue("title"), !title.isEmpty else {
            return CallTool.Result(
                content: [.text("Error: 'title' parameter is required and must not be empty")], isError: true)
        }

        var state: TaskItemState = .open
        if let stateStr = arguments?.stringValue("state") {
            guard let parsed = parseState(stateStr),
                [.open, .priority, .pendingResponse].contains(parsed)
            else {
                return CallTool.Result(
                    content: [
                        .text("Error: Invalid state '\(stateStr)'. Allowed for create: open, priority, pendingResponse")
                    ],
                    isError: true)
            }
            state = parsed
        }

        let context = ModelContext(container)
        let task = TaskItem(title: title, changedDate: timeProvider.now, state: state)

        if let details = arguments?.stringValue("details") {
            task.setDetails(details)
        }
        if let dueDateStr = arguments?.stringValue("due_date") {
            guard let date = parseDateOnly(dueDateStr) else {
                return CallTool.Result(
                    content: [.text("Error: Invalid date format '\(dueDateStr)'. Expected YYYY-MM-DD")], isError: true)
            }
            task.setDueDate(date)
        }
        if let tags = arguments?.stringArrayValue("tags") {
            task.updateTags(tags, createComments: false)
        }

        context.insert(task)
        try context.save()

        let summary = serializeSummary(task, prefix: shortIdPrefix)
        return CallTool.Result(content: [.text(toJSON(summary))])
    }

    private func handleUpdateTask(_ arguments: [String: Value]?) async throws -> CallTool.Result {
        let context = ModelContext(container)
        switch try resolveTask(from: arguments, in: context) {
        case .failure(let error): return error
        case .success(let task):
            if let title = arguments?.stringValue("title") {
                task.setTitle(title)
            }
            if let details = arguments?.stringValue("details") {
                task.setDetails(details)
            }
            if let url = arguments?.stringValue("url") {
                task.setUrl(url)
            }
            if let dueDateStr = arguments?.stringValue("due_date") {
                if dueDateStr.isEmpty {
                    task.setDueDate(nil)
                } else {
                    guard let date = parseDateOnly(dueDateStr) else {
                        return CallTool.Result(
                            content: [.text("Error: Invalid date format '\(dueDateStr)'. Expected YYYY-MM-DD")],
                            isError: true)
                    }
                    task.setDueDate(date)
                }
            }
            if let minutes = arguments?.intValue("estimated_minutes") {
                task.setEstimatedMinutes(minutes)
            }

            try context.save()

            let summary = serializeSummary(task, prefix: shortIdPrefix)
            return CallTool.Result(content: [.text(toJSON(summary))])
        }
    }

    private func handleManageTags(_ arguments: [String: Value]?) async throws -> CallTool.Result {
        guard let action = arguments?.stringValue("action"),
            ["add", "remove", "set"].contains(action)
        else {
            return CallTool.Result(content: [.text("Error: 'action' must be 'add', 'remove', or 'set'")], isError: true)
        }
        guard let tags = arguments?.stringArrayValue("tags") else {
            return CallTool.Result(content: [.text("Error: 'tags' array is required")], isError: true)
        }

        let context = ModelContext(container)
        switch try resolveTask(from: arguments, in: context) {
        case .failure(let error): return error
        case .success(let task):
            switch action {
            case "add":
                for tag in tags {
                    task.addTag(tag)
                }
            case "remove":
                for tag in tags {
                    task.removeTag(tag)
                }
            case "set":
                task.updateTags(tags)
            default:
                break
            }

            try context.save()

            let summary = serializeSummary(task, prefix: shortIdPrefix)
            return CallTool.Result(content: [.text(toJSON(summary))])
        }
    }

    // MARK: - Helpers

    private func parseState(_ string: String) -> TaskItemState? {
        switch string.lowercased() {
        case "open": return .open
        case "priority": return .priority
        case "pendingresponse", "pending": return .pendingResponse
        case "closed": return .closed
        case "dead", "graveyard": return .dead
        default: return nil
        }
    }
}

// MARK: - Value Extraction Helpers

extension [String: Value] {
    func stringValue(_ key: String) -> String? {
        guard let val = self[key] else { return nil }
        if case .string(let s) = val { return s }
        return nil
    }

    func intValue(_ key: String) -> Int? {
        guard let val = self[key] else { return nil }
        if case .int(let i) = val { return i }
        if case .double(let d) = val { return Int(d) }
        if case .string(let s) = val { return Int(s) }
        return nil
    }

    func stringArrayValue(_ key: String) -> [String]? {
        guard let val = self[key] else { return nil }
        if case .array(let arr) = val {
            return arr.compactMap { element in
                if case .string(let s) = element { return s }
                return nil
            }
        }
        return nil
    }
}
