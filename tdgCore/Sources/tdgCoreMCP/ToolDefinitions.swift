import MCP

public let allTools: [Tool] = [
    findTasksTool,
    getTaskTool,
    getStatisticsTool,
    getCompassCheckStatusTool,
    getPreferencesTool,
    listTagsTool,
    createTaskTool,
    updateTaskTool,
    manageTagsTool,
]

let findTasksTool = Tool(
    name: "find_tasks",
    description:
        "Search and filter tasks. Returns a summary list (id, short_id, title, state, tags, due_date, changed, created). All filters are AND-combined. With no parameters, returns all tasks.",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "query": .object([
                "type": .string("string"),
                "description": .string("Full-text search across title, details, and tags (case-insensitive)"),
            ]),
            "state": .object([
                "type": .string("string"),
                "description": .string("Filter by task state"),
                "enum": .array([
                    .string("open"), .string("priority"), .string("pendingResponse"), .string("closed"),
                    .string("dead"),
                ]),
            ]),
            "tags": .object([
                "type": .string("array"),
                "items": .object(["type": .string("string")]),
                "description": .string("Filter by tags. Tasks must have ALL specified tags."),
            ]),
            "due_within_days": .object([
                "type": .string("integer"),
                "description": .string("Only return tasks with a due date within this many days from today"),
            ]),
        ]),
    ]),
    annotations: .init(readOnlyHint: true, openWorldHint: false)
)

let getTaskTool = Tool(
    name: "get_task",
    description:
        "Get full details of a single task including comments (audit trail), attachment metadata, details, URL, and estimated minutes.",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "id": .object([
                "type": .string("string"),
                "description": .string("The task ID — full UUID, short ID (e.g. TDG-A1B2C3D4), or bare 8-char hex"),
            ])
        ]),
        "required": .array([.string("id")]),
    ]),
    annotations: .init(readOnlyHint: true, openWorldHint: false)
)

let getStatisticsTool = Tool(
    name: "get_statistics",
    description:
        "Get task counts grouped by state (open, priority, pendingResponse, closed, dead). Optionally filter by a specific tag to see how many tasks with that tag are in each state.",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "tag": .object([
                "type": .string("string"),
                "description": .string("If provided, only count tasks that have this tag"),
            ])
        ]),
    ]),
    annotations: .init(readOnlyHint: true, openWorldHint: false)
)

let getCompassCheckStatusTool = Tool(
    name: "get_compass_check_status",
    description:
        "Get the Compass Check daily review status: current streak, longest streak, last check date, and whether the check was done today. Note: data may be stale if the app has not synced recently.",
    inputSchema: .object([
        "type": .string("object")
    ]),
    annotations: .init(readOnlyHint: true, openWorldHint: false)
)

let getPreferencesTool = Tool(
    name: "get_preferences",
    description:
        "Get app preferences: task expiry days, compass check scheduled time, notification settings, and short ID prefix. Note: data may be stale if the app has not synced recently.",
    inputSchema: .object([
        "type": .string("object")
    ]),
    annotations: .init(readOnlyHint: true, openWorldHint: false)
)

let listTagsTool = Tool(
    name: "list_tags",
    description: "List all tags with the number of active tasks (open + priority + pendingResponse) using each tag.",
    inputSchema: .object([
        "type": .string("object")
    ]),
    annotations: .init(readOnlyHint: true, openWorldHint: false)
)

let createTaskTool = Tool(
    name: "create_task",
    description:
        "Create a new task. Returns the created task summary. State is restricted to open (default), priority, or pendingResponse.",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "title": .object([
                "type": .string("string"),
                "description": .string("The task title (required)"),
            ]),
            "details": .object([
                "type": .string("string"),
                "description": .string("Task description/details"),
            ]),
            "tags": .object([
                "type": .string("array"),
                "items": .object(["type": .string("string")]),
                "description": .string("Tags to assign to the task"),
            ]),
            "due_date": .object([
                "type": .string("string"),
                "description": .string("Due date in YYYY-MM-DD format"),
            ]),
            "state": .object([
                "type": .string("string"),
                "description": .string("Initial state (default: open)"),
                "enum": .array([.string("open"), .string("priority"), .string("pendingResponse")]),
            ]),
        ]),
        "required": .array([.string("title")]),
    ]),
    annotations: .init(destructiveHint: false, idempotentHint: false, openWorldHint: false)
)

let updateTaskTool = Tool(
    name: "update_task",
    description:
        "Update an existing task's properties. Only provided fields are changed. Returns the updated task summary.",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "id": .object([
                "type": .string("string"),
                "description": .string(
                    "The task ID — full UUID, short ID (e.g. TDG-A1B2C3D4), or bare 8-char hex (required)"),
            ]),
            "title": .object([
                "type": .string("string"),
                "description": .string("New title"),
            ]),
            "details": .object([
                "type": .string("string"),
                "description": .string("New description/details"),
            ]),
            "url": .object([
                "type": .string("string"),
                "description": .string("New URL"),
            ]),
            "due_date": .object([
                "type": .string("string"),
                "description": .string("New due date in YYYY-MM-DD format, or empty string to clear"),
            ]),
            "estimated_minutes": .object([
                "type": .string("integer"),
                "description": .string("Estimated effort in minutes"),
            ]),
        ]),
        "required": .array([.string("id")]),
    ]),
    annotations: .init(destructiveHint: false, idempotentHint: true, openWorldHint: false)
)

let manageTagsTool = Tool(
    name: "manage_tags",
    description:
        "Add, remove, or replace tags on a task. 'add' appends tags, 'remove' removes specific tags, 'set' replaces all tags. Returns the updated task summary.",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "id": .object([
                "type": .string("string"),
                "description": .string(
                    "The task ID — full UUID, short ID (e.g. TDG-A1B2C3D4), or bare 8-char hex (required)"),
            ]),
            "action": .object([
                "type": .string("string"),
                "description": .string("Tag action: add, remove, or set"),
                "enum": .array([.string("add"), .string("remove"), .string("set")]),
            ]),
            "tags": .object([
                "type": .string("array"),
                "items": .object(["type": .string("string")]),
                "description": .string("Tags to add, remove, or set"),
            ]),
        ]),
        "required": .array([.string("id"), .string("action"), .string("tags")]),
    ]),
    annotations: .init(destructiveHint: false, idempotentHint: false, openWorldHint: false)
)
