//
//  TaskPreviewCard.swift
//  Three Daily Goals
//
//  Hover (macOS) / long-press (iOS) preview of a task — shows enough
//  context to decide whether to act on it without opening the detail view.
//

import SwiftUI
import tdgCoreMain
import tdgCoreWidget

struct TaskPreviewCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(TimeProviderWrapper.self) private var timeProviderWrapper

    let item: TaskItem

    private var quadrant: EnergyEffortQuadrant? {
        EnergyEffortQuadrant.from(task: item)
    }

    private var hasNotes: Bool {
        !item.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && item.details != emptyTaskDetails
    }

    private var tags: [String] {
        Self.visibleTags(for: item)
    }

    private var activity: [Comment] {
        Self.recentActivity(for: item, limit: 3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.title)
                .font(.headline)
                .lineLimit(3)

            chips

            section("Notes") {
                if hasNotes {
                    Text(item.details)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .lineLimit(6)
                } else {
                    Text("No notes yet — add some to remember why this matters.")
                        .font(.callout)
                        .italic()
                        .foregroundStyle(.secondary)
                }
            }

            if !tags.isEmpty {
                section("Tags") {
                    tagWrap
                }
            }

            if !activity.isEmpty {
                section("Recent activity") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(activity, id: \.created) { comment in
                            activityRow(comment)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                Text("Created \(item.created.formatted(date: .abbreviated, time: .omitted))")
                Text("·")
                Text("Touched \(timeProviderWrapper.timeProvider.timeRemaining(for: item.changed))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            #if os(macOS)
                Divider()
                HStack(spacing: 10) {
                    keyboardHint("Space", label: "open")
                    keyboardHint("★", label: "set priority")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            #endif
        }
        .padding(14)
        #if os(macOS)
            // macOS popover already provides window chrome (background + arrow).
            // Pin to the design's 340pt and let the popover host the card.
            .frame(width: 340, alignment: .leading)
        #else
            // iOS .contextMenu(preview:) wraps the view in its own blurred,
            // rounded container — don't add a competing background. Allow the
            // system to size the preview within a reasonable range.
            .frame(minWidth: 280, idealWidth: 340, maxWidth: 380, alignment: .leading)
        #endif
    }

    // MARK: - Chip row

    private var chips: some View {
        HStack(spacing: 6) {
            chip(
                icon: item.state.imageName,
                text: stateLabel(item.state),
                tint: item.state.color
            )
            if let q = quadrant {
                chip(icon: q.icon, text: q.name, tint: q.color)
            }
            if let due = item.due {
                chip(
                    icon: imgPendingResponse,
                    text: timeProviderWrapper.timeProvider.timeRemaining(for: due),
                    tint: isDueUrgent(due) ? Color.dueSoon : Color.secondary
                )
            }
        }
    }

    private func chip(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).imageScale(.small)
            Text(text)
        }
        .font(.caption)
        .foregroundStyle(tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(tint.opacity(0.15))
        .clipShape(.rect(cornerRadius: 10))
    }

    // MARK: - Tags

    private var tagWrap: some View {
        TagFlowLayout(spacing: 4) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .foregroundStyle(Color.priority)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.priority.opacity(0.12))
                    .clipShape(.rect(cornerRadius: 4))
            }
        }
    }

    // MARK: - Activity row

    private func activityRow(_ comment: Comment) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(comment.created.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)
            Text(comment.text)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
    }

    // MARK: - Section helper

    @ViewBuilder
    private func section<Content: View>(
        _ title: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
                .tracking(0.6)
            content()
        }
    }

    // MARK: - Keyboard hint (macOS only)

    #if os(macOS)
        private func keyboardHint(_ key: String, label: String) -> some View {
            HStack(spacing: 4) {
                Text(key)
                    .font(.caption2.monospaced())
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.neutral200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.neutral300, lineWidth: 0.5)
                    )
                    .clipShape(.rect(cornerRadius: 3))
                Text(label)
            }
        }
    #endif

    // MARK: - Helpers

    private func stateLabel(_ state: TaskItemState) -> String {
        state.description.prefix(1).uppercased() + state.description.dropFirst()
    }

    private func isDueUrgent(_ date: Date) -> Bool {
        let now = timeProviderWrapper.timeProvider.now
        return date.timeIntervalSince(now) < 24 * 60 * 60
    }

    // MARK: - Pure helpers (exposed for testing)

    /// Tags the preview should display — excludes the Energy-Effort matrix tags,
    /// because the quadrant chip already conveys that information.
    static func visibleTags(for item: TaskItem) -> [String] {
        let matrixTags: Set<String> = ["high-energy", "low-energy", "big-task", "small-task"]
        return item.tags.filter { !matrixTags.contains($0) }
    }

    /// Returns up to `limit` of the task's most recent comments, newest first.
    static func recentActivity(for item: TaskItem, limit: Int) -> [Comment] {
        let comments = item.comments ?? []
        return comments
            .sorted { $0.created > $1.created }
            .prefix(limit)
            .map { $0 }
    }
}

// MARK: - Minimal flow layout for tag wrapping

private struct TagFlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var lineWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if lineWidth + size.width > maxWidth, lineWidth > 0 {
                totalHeight += lineHeight + spacing
                lineWidth = 0
                lineHeight = 0
            }
            lineWidth += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        totalHeight += lineHeight
        return CGSize(width: maxWidth == .infinity ? lineWidth : maxWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

#Preview {
    let appComp = setupApp(isTesting: true)
    TaskPreviewCard(item: appComp.dataManager.allTasks.first!)
        .environment(appComp.dataManager)
        .environment(appComp.preferences)
        .environment(appComp.timeProviderWrapper)
        .padding()
}
