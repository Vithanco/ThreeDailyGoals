import SwiftData
import Foundation
import UniformTypeIdentifiers
import CryptoKit

public typealias Attachment = SchemaLatest.Attachment

extension Data {
    var sha256Hex: String {
        let digest = SHA256.hash(data: self)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

func addAttachment(fileURL: URL,
                   type: UTType,
                   to taskItem: TaskItem,
                   sortIndex: Int? = nil,
                   caption: String? = nil,
                   makeBookmark: Bool = true,
                   in context: ModelContext) throws -> Attachment {
    let rv = try fileURL.resourceValues(forKeys: [.fileSizeKey, .localizedNameKey])
    let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
    let hash = data.sha256Hex

    if let existing = try? context.fetch(
        FetchDescriptor<Attachment>(predicate: #Predicate { $0.taskItem == taskItem && $0.sha256 == hash })
    ).first { return existing }

    let att = Attachment()
    att.blob = data
    att.thumbnail = makeThumbnail(from: data, type: type)
    att.filename = rv.localizedName ?? fileURL.lastPathComponent
    att.utiIdentifier = type.identifier
    att.byteSize = rv.fileSize ?? data.count
    att.sha256 = hash
    att.caption = caption
    att.sortIndex = sortIndex ?? taskItem.attachments?.count ?? 0
    att.createdAt = .now
    att.modifiedAt = .now
    if makeBookmark {
        att.sourceBookmark = try? fileURL.bookmarkData(options: .withSecurityScope,
                                                       includingResourceValuesForKeys: nil,
                                                       relativeTo: nil)
    }
    att.isPurged = false
    att.purgedAt = nil
    att.taskItem = taskItem

    context.insert(att)
    try context.save()
    return att
}

extension Attachment {
    func purge(in context: ModelContext) throws {
        self.blob = nil
        self.isPurged = true
        self.purgedAt = .now
        self.nextPurgePrompt = nil
        try context.save()
    }
    
    func scheduleNextPurgePrompt(months: Int, in context: ModelContext) throws {
        self.nextPurgePrompt = Calendar.current.date(byAdding: .month, value: months, to: .now)
        try context.save()
    }
    
    func isDueForPurge(at date: Date = .now) -> Bool {
        !isPurged && (nextPurgePrompt?.compare(date) != .orderedDescending)
    }
    
    var storedBytes: Int { blob?.count ?? 0 }
}


