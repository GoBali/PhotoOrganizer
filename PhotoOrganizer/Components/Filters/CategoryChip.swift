//
//  CategoryChip.swift
//  PhotoOrganizer
//
//  Individual category filter chip component with gradient and animations
//

import SwiftUI

struct CategoryChip: View {
    let title: String
    let count: Int?
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    init(
        _ title: String,
        count: Int? = nil,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.count = count
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button {
            #if os(iOS)
            HapticStyle.selection.trigger()
            #endif
            action()
        } label: {
            HStack(spacing: Spacing.space1) {
                Text(title)
                    .font(.callout.weight(isSelected ? .semibold : .regular))

                if let count, count > 0 {
                    CountBadge(count: count, isSelected: isSelected)
                }
            }
            .foregroundStyle(isSelected ? Color.ds.textOnAccent : Color.ds.textPrimary)
            .padding(.horizontal, Spacing.space4)
            .padding(.vertical, Spacing.space2)
            .background(chipBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.clear : Color.ds.border,
                        lineWidth: BorderWidth.thin
                    )
            )
        }
        .buttonStyle(CategoryChipButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(Motion.springBouncy(), value: isSelected)
        .accessibilityLabel("\(title)\(count.map { ", \($0) photos" } ?? "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint("Double tap to filter by \(title)")
    }

    @ViewBuilder
    private var chipBackground: some View {
        if isSelected {
            LinearGradient(
                colors: [Color.ds.secondary, Color.ds.secondaryVariant],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.ds.surfaceSecondary
        }
    }
}

// MARK: - Count Badge

private struct CountBadge: View {
    let count: Int
    let isSelected: Bool

    var body: some View {
        Text("\(count)")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, Spacing.space1 + 2)
            .padding(.vertical, 2)
            .background(badgeBackground)
            .foregroundStyle(isSelected ? Color.ds.textOnAccent : Color.ds.textSecondary)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var badgeBackground: some View {
        if isSelected {
            Color.white.opacity(0.25)
        } else {
            Color.ds.surfaceTertiary
        }
    }
}

// MARK: - Button Style

struct CategoryChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(Motion.springStiff(), value: configuration.isPressed)
    }
}

// MARK: - Category Chip with Icon

struct CategoryChipWithIcon: View {
    let title: String
    let icon: String
    let count: Int?
    let isSelected: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String,
        count: Int? = nil,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.count = count
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button {
            #if os(iOS)
            HapticStyle.selection.trigger()
            #endif
            action()
        } label: {
            HStack(spacing: Spacing.space2) {
                Image(systemName: icon)
                    .font(.system(size: IconSize.small, weight: .medium))

                Text(title)
                    .font(.callout.weight(isSelected ? .semibold : .regular))

                if let count, count > 0 {
                    CountBadge(count: count, isSelected: isSelected)
                }
            }
            .foregroundStyle(isSelected ? Color.ds.textOnAccent : Color.ds.textPrimary)
            .padding(.horizontal, Spacing.space4)
            .padding(.vertical, Spacing.space2)
            .background(chipBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.clear : Color.ds.border,
                        lineWidth: BorderWidth.thin
                    )
            )
        }
        .buttonStyle(CategoryChipButtonStyle())
        .animation(Motion.springBouncy(), value: isSelected)
        .accessibilityLabel("\(title)\(count.map { ", \($0) photos" } ?? "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    @ViewBuilder
    private var chipBackground: some View {
        if isSelected {
            LinearGradient(
                colors: [Color.ds.secondary, Color.ds.secondaryVariant],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.ds.surfaceSecondary
        }
    }
}

// MARK: - Preview

#Preview("Category Chips") {
    VStack(spacing: 24) {
        Text("Basic Chips")
            .typography(.headline)

        HStack(spacing: 8) {
            CategoryChip("All", count: 42, isSelected: true) {}
            CategoryChip("Nature", count: 15, isSelected: false) {}
            CategoryChip("Portrait", count: 8, isSelected: false) {}
        }

        Text("With Icons")
            .typography(.headline)

        HStack(spacing: 8) {
            CategoryChipWithIcon("All", icon: "square.grid.2x2", count: 42, isSelected: true) {}
            CategoryChipWithIcon("Favorites", icon: "heart.fill", count: 5, isSelected: false) {}
        }

        Text("Without Counts")
            .typography(.headline)

        HStack(spacing: 8) {
            CategoryChip("Urban", isSelected: false) {}
            CategoryChip("Food", isSelected: true) {}
        }
    }
    .padding()
    .background(Color.ds.background)
}
