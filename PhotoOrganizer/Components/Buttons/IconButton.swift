//
//  IconButton.swift
//  PhotoOrganizer
//
//  Icon-only button component
//

import SwiftUI

struct IconButton: View {
    let icon: String
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void

    init(
        icon: String,
        size: CGFloat = ComponentSize.minTapTarget,
        backgroundColor: Color = Color.ds.surfaceSecondary,
        foregroundColor: Color = Color.ds.textPrimary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.bold())
        }
        .iconButtonStyle(
            size: size,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        )
    }
}

// MARK: - Semantic Icon Buttons

extension IconButton {
    /// Back navigation button
    static func back(action: @escaping () -> Void) -> IconButton {
        IconButton(
            icon: "chevron.left",
            action: action
        )
    }

    /// Close/dismiss button
    static func close(action: @escaping () -> Void) -> IconButton {
        IconButton(
            icon: "xmark",
            action: action
        )
    }

    /// Add/plus button
    static func add(action: @escaping () -> Void) -> IconButton {
        IconButton(
            icon: "plus",
            backgroundColor: Color.ds.secondary,
            foregroundColor: Color.ds.textOnAccent,
            action: action
        )
    }

    /// Delete button
    static func delete(action: @escaping () -> Void) -> IconButton {
        IconButton(
            icon: "trash",
            backgroundColor: Color.ds.errorBackground,
            foregroundColor: Color.ds.error,
            action: action
        )
    }

    /// Refresh/reclassify button
    static func refresh(action: @escaping () -> Void) -> IconButton {
        IconButton(
            icon: "arrow.triangle.2.circlepath",
            action: action
        )
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        IconButton.back {}
        IconButton.close {}
        IconButton.add {}
        IconButton.delete {}
        IconButton.refresh {}
    }
    .padding()
    .background(Color.ds.background)
}
