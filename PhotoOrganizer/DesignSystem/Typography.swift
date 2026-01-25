//
//  Typography.swift
//  PhotoOrganizer
//
//  Dynamic Type support with semantic text styles
//

import SwiftUI

// MARK: - Typography Styles

/// Semantic typography styles using Dynamic Type
enum Typography {
    /// Screen titles - .title.bold()
    case title1
    /// Section titles - .title3.weight(.semibold)
    case title3
    /// Card titles, buttons - .headline
    case headline
    /// Body text - .body
    case body
    /// Description text - .callout
    case callout
    /// Badges, metadata - .caption
    case caption1
    /// Small labels - .caption2
    case caption2

    var font: Font {
        switch self {
        case .title1:
            return .title.bold()
        case .title3:
            return .title3.weight(.semibold)
        case .headline:
            return .headline
        case .body:
            return .body
        case .callout:
            return .callout
        case .caption1:
            return .caption
        case .caption2:
            return .caption2
        }
    }
}

// MARK: - View Extension for Typography

extension View {
    /// Apply semantic typography style
    func typography(_ style: Typography) -> some View {
        self.font(style.font)
    }

    /// Apply typography with color
    func typography(_ style: Typography, color: Color) -> some View {
        self
            .font(style.font)
            .foregroundStyle(color)
    }
}

// MARK: - Text Extension

extension Text {
    /// Create styled text with typography
    func styled(_ style: Typography) -> Text {
        self.font(style.font)
    }

    /// Create styled text with typography and color
    func styled(_ style: Typography, color: Color) -> some View {
        self
            .font(style.font)
            .foregroundStyle(color)
    }
}

// MARK: - Preview

#Preview("Typography Styles") {
    VStack(alignment: .leading, spacing: 16) {
        Text("Title 1 - Screen Titles")
            .typography(.title1, color: .ds.textPrimary)

        Text("Title 3 - Section Titles")
            .typography(.title3, color: .ds.textPrimary)

        Text("Headline - Card Titles, Buttons")
            .typography(.headline, color: .ds.textPrimary)

        Text("Body - Body Text")
            .typography(.body, color: .ds.textPrimary)

        Text("Callout - Description Text")
            .typography(.callout, color: .ds.textSecondary)

        Text("Caption 1 - Badges, Metadata")
            .typography(.caption1, color: .ds.textSecondary)

        Text("Caption 2 - Small Labels")
            .typography(.caption2, color: .ds.textTertiary)
    }
    .padding()
    .background(Color.ds.background)
}
