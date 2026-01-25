//
//  ConfidenceBadge.swift
//  PhotoOrganizer
//
//  Confidence level badge with color-coded display
//

import SwiftUI

enum ConfidenceLevel {
    case high       // 80%+
    case medium     // 50-80%
    case low        // < 50%
    case unknown    // 0% or no data

    init(confidence: Double) {
        switch confidence {
        case 0.8...1.0:
            self = .high
        case 0.5..<0.8:
            self = .medium
        case 0.01..<0.5:
            self = .low
        default:
            self = .unknown
        }
    }

    var color: Color {
        switch self {
        case .high:
            return Color.ds.success
        case .medium:
            return Color.ds.warning
        case .low:
            return Color.ds.error
        case .unknown:
            return Color.ds.textTertiary
        }
    }

    var backgroundColor: Color {
        switch self {
        case .high:
            return Color.ds.successBackground
        case .medium:
            return Color.ds.warningBackground
        case .low:
            return Color.ds.errorBackground
        case .unknown:
            return Color.ds.surfaceSecondary
        }
    }

    var icon: String {
        switch self {
        case .high:
            return "checkmark.circle.fill"
        case .medium:
            return "exclamationmark.circle.fill"
        case .low:
            return "xmark.circle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - Confidence Badge

struct ConfidenceBadge: View {
    let confidence: Double
    let showPercentage: Bool
    let size: BadgeSize

    enum BadgeSize {
        case small
        case medium
        case large

        var iconSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 14
            case .large: return 16
            }
        }

        var fontSize: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium:
                return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large:
                return EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
            }
        }
    }

    private var level: ConfidenceLevel {
        ConfidenceLevel(confidence: confidence)
    }

    init(confidence: Double, showPercentage: Bool = true, size: BadgeSize = .medium) {
        self.confidence = confidence
        self.showPercentage = showPercentage
        self.size = size
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
                .font(.system(size: size.iconSize, weight: .semibold))

            if showPercentage {
                Text("\(Int(confidence * 100))%")
                    .font(size.fontSize.weight(.semibold))
            }
        }
        .foregroundStyle(level.color)
        .padding(size.padding)
        .background(level.backgroundColor)
        .clipShape(Capsule())
    }
}

// MARK: - Inline Confidence Indicator (smaller, for cards)

struct InlineConfidenceIndicator: View {
    let confidence: Double

    private var level: ConfidenceLevel {
        ConfidenceLevel(confidence: confidence)
    }

    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(level.color)
                .frame(width: 6, height: 6)
            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(level.color)
        }
    }
}

// MARK: - Preview

#Preview("Confidence Badges") {
    VStack(spacing: Spacing.space4) {
        VStack(alignment: .leading, spacing: Spacing.space2) {
            Text("Sizes").typography(.headline)
            HStack(spacing: Spacing.space2) {
                ConfidenceBadge(confidence: 0.95, size: .small)
                ConfidenceBadge(confidence: 0.95, size: .medium)
                ConfidenceBadge(confidence: 0.95, size: .large)
            }
        }

        VStack(alignment: .leading, spacing: Spacing.space2) {
            Text("Levels").typography(.headline)
            VStack(alignment: .leading, spacing: Spacing.space2) {
                ConfidenceBadge(confidence: 0.95)
                ConfidenceBadge(confidence: 0.65)
                ConfidenceBadge(confidence: 0.35)
                ConfidenceBadge(confidence: 0.0)
            }
        }

        VStack(alignment: .leading, spacing: Spacing.space2) {
            Text("Inline Indicator").typography(.headline)
            HStack {
                InlineConfidenceIndicator(confidence: 0.92)
                InlineConfidenceIndicator(confidence: 0.68)
                InlineConfidenceIndicator(confidence: 0.25)
            }
        }
    }
    .padding()
    .background(Color.ds.background)
}
