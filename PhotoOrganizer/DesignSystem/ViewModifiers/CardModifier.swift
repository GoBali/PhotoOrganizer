//
//  CardModifier.swift
//  PhotoOrganizer
//
//  Card style modifier replacing GlassModifier
//

import SwiftUI

// MARK: - Card Modifier

struct CardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let elevation: Elevation
    let hasBorder: Bool

    init(
        cornerRadius: CGFloat = CornerRadius.large,
        elevation: Elevation = .low,
        hasBorder: Bool = true
    ) {
        self.cornerRadius = cornerRadius
        self.elevation = elevation
        self.hasBorder = hasBorder
    }

    func body(content: Content) -> some View {
        content
            .background(Color.ds.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .elevation(elevation)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(hasBorder ? Color.ds.border : .clear, lineWidth: 1)
            )
    }
}

// MARK: - Section Card Modifier

struct SectionCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.space4)
            .background(Color.ds.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .elevation(.low)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                    .stroke(Color.ds.border, lineWidth: 1)
            )
    }
}

// MARK: - Photo Card Modifier (for grid items)

struct PhotoCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .elevation(.low)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply card style with customizable parameters
    func card(
        cornerRadius: CGFloat = CornerRadius.large,
        elevation: Elevation = .low,
        hasBorder: Bool = true
    ) -> some View {
        modifier(CardModifier(
            cornerRadius: cornerRadius,
            elevation: elevation,
            hasBorder: hasBorder
        ))
    }

    /// Apply section card style with padding
    func sectionCard() -> some View {
        modifier(SectionCardModifier())
    }

    /// Apply photo card style (for grid items)
    func photoCard() -> some View {
        modifier(PhotoCardModifier())
    }
}

// MARK: - Preview

#Preview("Card Styles") {
    VStack(spacing: 24) {
        // Standard Card
        VStack(alignment: .leading, spacing: 8) {
            Text("Standard Card")
                .typography(.headline, color: .ds.textPrimary)
            Text("This is a standard card with low elevation")
                .typography(.body, color: .ds.textSecondary)
        }
        .padding()
        .card()

        // Section Card
        VStack(alignment: .leading, spacing: 8) {
            Text("Section Card")
                .typography(.headline, color: .ds.textPrimary)
            Text("This card has built-in padding")
                .typography(.body, color: .ds.textSecondary)
        }
        .sectionCard()

        // Medium Elevation Card
        VStack(alignment: .leading, spacing: 8) {
            Text("Medium Elevation")
                .typography(.headline, color: .ds.textPrimary)
            Text("More prominent shadow")
                .typography(.body, color: .ds.textSecondary)
        }
        .padding()
        .card(elevation: .medium)
    }
    .padding()
    .background(Color.ds.background)
}
