import SwiftUI

struct MasonryGrid<Content: View>: View {
    let items: [MediaItem]
    let width: CGFloat
    let columnCount: Int
    let spacing: CGFloat
    let content: (MediaItem) -> Content

    var body: some View {
        let count = max(1, columnCount)
        let columnWidth = (width - spacing * CGFloat(count - 1)) / CGFloat(count)
        let columns = MasonryLayout.buildColumns(
            items: items,
            columnCount: count,
            columnWidth: columnWidth,
            spacing: spacing
        )

        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns.count, id: \.self) { index in
                VStack(spacing: spacing) {
                    ForEach(columns[index]) { item in
                        content(item)
                    }
                }
            }
        }
    }
}

enum MasonryLayout {
    static func buildColumns(
        items: [MediaItem],
        columnCount: Int,
        columnWidth: CGFloat,
        spacing: CGFloat
    ) -> [[MediaItem]] {
        guard columnCount > 0 else { return [] }
        var columns = Array(repeating: [MediaItem](), count: columnCount)
        var heights = Array(repeating: CGFloat(0), count: columnCount)

        for item in items {
            let height = estimatedHeight(for: item, columnWidth: columnWidth)
            let target = heights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            columns[target].append(item)
            heights[target] += height + spacing
        }

        return columns
    }

    private static func estimatedHeight(for item: MediaItem, columnWidth: CGFloat) -> CGFloat {
        guard let w = item.width, let h = item.height, w > 0, h > 0 else {
            return columnWidth
        }
        let ratio = CGFloat(h) / CGFloat(w)
        return columnWidth * ratio
    }
}
