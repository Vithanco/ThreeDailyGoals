import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct AttachmentRow: View {
    let attachment: Attachment
    let onDelete: (() -> Void)?
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(spacing: 12) {
            thumb.clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.filename).lineLimit(1)
                if let c = attachment.caption, !c.isEmpty { Text(c).font(.caption) }
                Text(byteCount).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let url = tempURL(), !attachment.isPurged {
                ShareLink(item: url)
                Button("Open") { 
                    print("Open button pressed for URL: \(url)")
                    #if os(macOS)
                    let success = NSWorkspace.shared.open(url)
                    print("NSWorkspace.open result: \(success)")
                    #else
                    // On iOS, we need to ensure the file is accessible
                    if FileManager.default.fileExists(atPath: url.path) {
                        openURL(url)
                    } else {
                        print("File does not exist at path: \(url.path)")
                    }
                    #endif
                }
                if let onDelete = onDelete {
                    Button("Delete") {
                        onDelete()
                    }
                    .foregroundColor(.red)
                }
            } else if attachment.isPurged {
                Text("Purged").font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var thumb: some View {
        if let data = attachment.thumbnail, let img = Image(data: data) {
            img.resizable().scaledToFill().frame(width: 44, height: 44)
        } else if let t = attachment.type, t.conforms(to: .image),
                  let data = attachment.blob, let img = Image(data: data) {
            img.resizable().scaledToFill().frame(width: 44, height: 44)
        } else if let url = tempURL() {
            FileThumbnailView(url: url, size: .init(width: 44, height: 44))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(.quaternary)
                Image(systemName: symbolName()).imageScale(.large)
            }
            .frame(width: 44, height: 44)
        }
    }

    private func symbolName() -> String {
        guard let t = attachment.type else { return "doc" }
        if t.conforms(to: .image) { return "photo" }
        if t == .pdf              { return "doc.richtext" }
        if t.conforms(to: .audio) { return "waveform" }
        if t.conforms(to: .video) { return "film" }
        return "doc"
    }

        private func tempURL() -> URL? {
        guard let data = attachment.blob, !attachment.isPurged else {
            print("tempURL: No blob data or attachment is purged")
            return nil
        }
        
        return createAttachmentTempFile(
            data: data,
            filename: attachment.filename,
            fileExtension: attachment.type?.preferredFilenameExtension,
            uniqueIdentifier: String(describing: attachment.id)
        )
    }

    private var byteCount: String {
        ByteCountFormatter.string(fromByteCount: Int64(attachment.byteSize), countStyle: .file)
    }
}
