import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct AttachmentRow: View {
    let attachment: Attachment
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
                Button("Open") { openURL(url) }
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
        guard let data = attachment.blob, !attachment.isPurged else { return nil }
        let ext = attachment.type?.preferredFilenameExtension
        let name = URL(fileURLWithPath: attachment.filename).deletingPathExtension().lastPathComponent
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(name)
            .appendingPathExtension(ext ?? URL(fileURLWithPath: attachment.filename).pathExtension)
        do {
            if !FileManager.default.fileExists(atPath: url.path) {
                try data.write(to: url, options: .atomic)
            }
            return url
        } catch { return nil }
    }

    private var byteCount: String {
        ByteCountFormatter.string(fromByteCount: Int64(attachment.byteSize), countStyle: .file)
    }
}
