import Foundation
import SwiftData
import UniformTypeIdentifiers

public typealias Attachment = SchemaLatest.Attachment

enum AttachmentError: LocalizedError {
    case fileTooLarge(fileSize: Int, maxSize: Int)

    var errorDescription: String? {
        switch self {
        case .fileTooLarge(let fileSize, let maxSize):
            let fileSizeMB = Double(fileSize) / (1024 * 1024)
            let maxSizeMB = Double(maxSize) / (1024 * 1024)
            return
                "File is too large (\(String(format: "%.1f", fileSizeMB))MB). Maximum size is \(String(format: "%.1f", maxSizeMB))MB."
        }
    }
}

// MARK: - Attachment Configuration
public let defaultMaxAttachmentSizeBytes = 20 * 1024 * 1024  // 20MB

public func addAttachment(
    fileURL: URL,
    type: UTType,
    to taskItem: TaskItem,
    sortIndex: Int? = nil,
    caption: String? = nil,
    maxSizeBytes: Int = defaultMaxAttachmentSizeBytes,
    in context: ModelContext
) throws -> Attachment {
    let rv = try fileURL.resourceValues(forKeys: [.fileSizeKey, .localizedNameKey])

    // Check file size before loading into memory
    let fileSize = rv.fileSize ?? 0
    if fileSize > maxSizeBytes {
        throw AttachmentError.fileTooLarge(fileSize: fileSize, maxSize: maxSizeBytes)
    }

    let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)

    let att = Attachment()
    att.blob = data
    att.thumbnail = makeThumbnail(from: data, type: type)
    att.filename = rv.localizedName ?? fileURL.lastPathComponent
    att.utiIdentifier = type.identifier
    att.byteSize = rv.fileSize ?? data.count
    att.caption = caption
    att.sortIndex = sortIndex ?? taskItem.attachments?.count ?? 0
    att.createdAt = .now
    att.isPurged = false
    att.purgedAt = nil
    att.taskItem = taskItem

    // Add attachment to task item's attachments array
    if taskItem.attachments == nil {
        taskItem.attachments = []
    }
    taskItem.attachments?.append(att)

    context.insert(att)
    try context.save()
    return att
}

extension Attachment {
    public func purge(in context: ModelContext) throws {
        self.blob = nil
        self.isPurged = true
        self.purgedAt = .now
        self.nextPurgePrompt = nil
        try context.save()
    }

    public func scheduleNextPurgePrompt(months: Int, in context: ModelContext, timeProvider: TimeProvider) throws {
        self.nextPurgePrompt = timeProvider.date(byAdding: .month, value: months, to: timeProvider.now)
        try context.save()
    }

    public func isDueForPurge(at date: Date = .now) -> Bool {
        guard !isPurged else { return false }
        guard let nextPurgePrompt = nextPurgePrompt else { return false }
        return nextPurgePrompt.compare(date) != .orderedDescending
    }

    public var storedBytes: Int { blob?.count ?? 0 }
}
