import Foundation
import tdgCoreMain
import tdgCoreWidget

func formatDate(_ date: Date?) -> String? {
    guard let date else { return nil }
    return date.ISO8601Format(.iso8601)
}

func parseDateOnly(_ string: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current
    return formatter.date(from: string)
}

@MainActor
func serializeSummary(_ task: TaskItem, prefix: String) -> [String: Any] {
    var dict: [String: Any] = [
        "id": task.uuid.uuidString,
        "short_id": ShortIdHelper.shortId(from: task.uuid, prefix: prefix),
        "title": task.title,
        "state": task.state.description,
        "tags": task.tags,
        "created": formatDate(task.created) as Any,
        "changed": formatDate(task.changed) as Any,
    ]
    if let dueDate = task.dueDate {
        dict["due_date"] = formatDate(dueDate)
    }
    return dict
}

@MainActor
func serializeDetail(_ task: TaskItem, prefix: String) -> [String: Any] {
    var dict = serializeSummary(task, prefix: prefix)
    dict["details"] = task.details
    dict["url"] = task.url.isEmpty ? nil : task.url
    dict["estimated_minutes"] = task.estimatedMinutes

    if let closed = task.closed {
        dict["closed"] = formatDate(closed)
    }
    if let eventId = task.eventId {
        dict["event_id"] = eventId
    }

    if let comments = task.comments {
        dict["comments"] = comments.sorted { $0.created < $1.created }.map { comment in
            var c: [String: Any] = [
                "text": comment.text,
                "created": formatDate(comment.created) as Any,
            ]
            if let icon = comment.icon {
                c["icon"] = icon
            }
            if let state = comment.state {
                c["state"] = state.description
            }
            return c
        }
    }

    if let attachments = task.attachments, !attachments.isEmpty {
        dict["attachments"] = attachments.map { attachment in
            var a: [String: Any] = [
                "filename": attachment.filename,
                "byte_size": attachment.byteSize,
                "created_at": formatDate(attachment.createdAt) as Any,
                "is_purged": attachment.isPurged,
            ]
            if let caption = attachment.caption {
                a["caption"] = caption
            }
            return a
        }
    }

    return dict
}

func toJSON(_ value: Any) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]),
        let string = String(data: data, encoding: .utf8)
    else {
        return "{}"
    }
    return string
}

func toJSON(_ values: [[String: Any]]) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: values, options: [.prettyPrinted, .sortedKeys]),
        let string = String(data: data, encoding: .utf8)
    else {
        return "[]"
    }
    return string
}
