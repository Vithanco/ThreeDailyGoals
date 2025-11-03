import SwiftUI

/// A layout that arranges its children in horizontal rows, wrapping to new lines as needed.
public struct FlowLayout<Content: View>: View {
    var alignment: HorizontalAlignment
    var spacing: CGFloat
    var runSpacing: CGFloat
    let content: () -> Content

    public init(
        alignment: HorizontalAlignment = .leading,
        spacing: CGFloat = 6,
        runSpacing: CGFloat = 6,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.runSpacing = runSpacing
        self.content = content
    }

    public var body: some View {
        AnyLayout(
            FlowLayoutImpl(
                alignment: alignment,
                spacing: spacing,
                runSpacing: runSpacing
            )
        ) {
            content()
        }
    }
}

private struct FlowLayoutImpl: Layout {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    let runSpacing: CGFloat

    init(alignment: HorizontalAlignment, spacing: CGFloat, runSpacing: CGFloat) {
        self.alignment = alignment
        self.spacing = spacing
        self.runSpacing = runSpacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + runSpacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + runSpacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
