//
//  GridColumnPicker.swift
//  PhotoOrganizer
//
//  Grid column count picker with icon-based segment control
//

import SwiftUI

struct GridColumnPicker: View {
    @Binding var columns: Int
    let range: ClosedRange<Int>

    init(columns: Binding<Int>, range: ClosedRange<Int> = 2...6) {
        self._columns = columns
        self.range = range
    }

    var body: some View {
        HStack(spacing: Spacing.space1) {
            ForEach(Array(range), id: \.self) { count in
                GridColumnButton(
                    count: count,
                    isSelected: columns == count
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        columns = count
                    }
                    #if os(iOS)
                    HapticStyle.light.trigger()
                    #endif
                }
            }
        }
        .padding(.horizontal, Spacing.space1)
        .padding(.vertical, Spacing.space1)
        .background(Color.ds.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
}

// MARK: - Grid Column Button

private struct GridColumnButton: View {
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    private var iconName: String {
        switch count {
        case 2: return "square.grid.2x2"
        case 3: return "square.grid.3x2"
        case 4: return "square.grid.3x3"
        case 5: return "rectangle.grid.3x2"
        case 6: return "rectangle.grid.2x2"
        default: return "square.grid.2x2"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .medium))
                Text("\(count)")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(isSelected ? Color.ds.textOnAccent : Color.ds.textSecondary)
            .frame(width: 36, height: 36)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(isSelected ? Color.ds.secondary : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(count) columns")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Compact Grid Column Picker (for toolbar)

struct CompactGridColumnPicker: View {
    @Binding var columns: Int
    let range: ClosedRange<Int>

    init(columns: Binding<Int>, range: ClosedRange<Int> = 2...6) {
        self._columns = columns
        self.range = range
    }

    var body: some View {
        Menu {
            ForEach(Array(range), id: \.self) { count in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        columns = count
                    }
                } label: {
                    HStack {
                        Text("\(count) columns")
                        if columns == count {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.space1) {
                Image(systemName: "square.grid.3x3")
                    .font(.system(size: 14, weight: .medium))
                Text("\(columns)")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Color.ds.textSecondary)
            .padding(.horizontal, Spacing.space2)
            .padding(.vertical, Spacing.space1)
            .background(Color.ds.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
        }
    }
}

// MARK: - Preview

#Preview("Grid Column Picker") {
    struct PreviewWrapper: View {
        @State private var columns = 4

        var body: some View {
            VStack(spacing: Spacing.space4) {
                Text("Selected: \(columns) columns")
                    .typography(.headline)

                GridColumnPicker(columns: $columns)

                CompactGridColumnPicker(columns: $columns)
            }
            .padding()
            .background(Color.ds.background)
        }
    }

    return PreviewWrapper()
}
