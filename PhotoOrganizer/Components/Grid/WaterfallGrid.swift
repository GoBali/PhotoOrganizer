//
//  WaterfallGrid.swift
//  PhotoOrganizer
//
//  True masonry/waterfall grid that places items in the shortest column
//

import SwiftUI

// MARK: - Waterfall Grid

struct WaterfallGrid<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let columns: Int
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    @State private var columnHeights: [CGFloat] = []
    @State private var itemPlacements: [Data.Element.ID: Int] = [:]

    init(
        data: Data,
        columns: Int = GridTokens.photoGridColumns,
        spacing: CGFloat = Spacing.space3,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            let columnWidth = (geometry.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)

            HStack(alignment: .top, spacing: spacing) {
                ForEach(0..<columns, id: \.self) { columnIndex in
                    VStack(spacing: spacing) {  // LazyVStack → VStack: environment 전파 안정화
                        ForEach(itemsForColumn(columnIndex)) { item in
                            content(item)
                                .frame(width: columnWidth)
                        }
                    }
                }
            }
        }
    }

    private func itemsForColumn(_ columnIndex: Int) -> [Data.Element] {
        var result: [Data.Element] = []
        var heights = Array(repeating: CGFloat.zero, count: columns)

        for item in data {
            // Find the column with minimum height
            let shortestColumnIndex = heights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0

            if shortestColumnIndex == columnIndex {
                result.append(item)
            }

            // Estimate height (use a default since we don't know actual height yet)
            // In practice, this distributes items evenly which works well for similar-sized items
            heights[shortestColumnIndex] += 200 + spacing
        }

        return result
    }
}

// MARK: - Preference Key for Height Tracking

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]

    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { $1 }
    }
}

// MARK: - Height Tracking Modifier

struct HeightTrackingModifier: ViewModifier {
    let id: String

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: HeightPreferenceKey.self,
                        value: [id: geometry.size.height]
                    )
                }
            )
    }
}

extension View {
    func trackHeight(id: String) -> some View {
        modifier(HeightTrackingModifier(id: id))
    }
}

// MARK: - Adaptive Waterfall Grid (with actual height tracking)

struct AdaptiveWaterfallGrid<Data: RandomAccessCollection, Content: View>: View
where Data.Element: Identifiable, Data.Element.ID: Hashable {
    let data: Data
    let columns: Int
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    @State private var itemHeights: [Data.Element.ID: CGFloat] = [:]

    init(
        data: Data,
        columns: Int = GridTokens.photoGridColumns,
        spacing: CGFloat = Spacing.space3,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            let columnWidth = (geometry.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            let columnAssignments = computeColumnAssignments()

            HStack(alignment: .top, spacing: spacing) {
                ForEach(0..<columns, id: \.self) { columnIndex in
                    VStack(spacing: spacing) {  // LazyVStack → VStack: environment 전파 안정화
                        ForEach(columnAssignments[columnIndex], id: \.id) { item in
                            content(item)
                                .frame(width: columnWidth)
                                .background(
                                    GeometryReader { itemGeometry in
                                        Color.clear
                                            .onAppear {
                                                itemHeights[item.id] = itemGeometry.size.height
                                            }
                                    }
                                )
                        }
                    }
                }
            }
        }
    }

    private func computeColumnAssignments() -> [[Data.Element]] {
        var result = Array(repeating: [Data.Element](), count: columns)
        var columnHeights = Array(repeating: CGFloat.zero, count: columns)

        for item in data {
            // Find the shortest column
            let shortestIndex = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0

            result[shortestIndex].append(item)

            // Use tracked height or estimate
            let itemHeight = itemHeights[item.id] ?? 200
            columnHeights[shortestIndex] += itemHeight + spacing
        }

        return result
    }
}

// MARK: - Preview

private struct WaterfallPreviewItem: Identifiable {
    let id = UUID()
    let height: CGFloat
    let color: Color
}

#Preview("Waterfall Grid") {
    let items = [
        WaterfallPreviewItem(height: 150, color: .blue),
        WaterfallPreviewItem(height: 200, color: .green),
        WaterfallPreviewItem(height: 120, color: .orange),
        WaterfallPreviewItem(height: 180, color: .purple),
        WaterfallPreviewItem(height: 160, color: .pink),
        WaterfallPreviewItem(height: 220, color: .cyan),
        WaterfallPreviewItem(height: 140, color: .yellow),
        WaterfallPreviewItem(height: 190, color: .red)
    ]

    ScrollView {
        WaterfallGrid(data: items, columns: 2, spacing: 12) { item in
            RoundedRectangle(cornerRadius: 12)
                .fill(item.color.opacity(0.5))
                .frame(height: item.height)
                .overlay {
                    Text("\(Int(item.height))pt")
                        .foregroundStyle(.white)
                        .font(.caption.bold())
                }
        }
        .padding()
    }
    .background(Color.ds.background)
}
