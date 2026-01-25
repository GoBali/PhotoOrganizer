//
//  ExtendedTokens.swift
//  PhotoOrganizer
//
//  Extended design tokens for opacity, borders, icons, and more
//

import SwiftUI

// MARK: - Opacity Tokens

enum Opacity {
    /// 0.04 - Subtle backgrounds
    static let subtle: Double = 0.04

    /// 0.08 - Hover states
    static let hover: Double = 0.08

    /// 0.12 - Pressed states
    static let pressed: Double = 0.12

    /// 0.32 - Scrim overlay
    static let scrim: Double = 0.32

    /// 0.4 - Disabled elements
    static let disabled: Double = 0.4

    /// 0.5 - Medium overlay
    static let overlay: Double = 0.5

    /// 0.7 - Heavy overlay
    static let heavy: Double = 0.7
}

// MARK: - Border Width Tokens

enum BorderWidth {
    /// 0.5pt - Hairline borders
    static let hairline: CGFloat = 0.5

    /// 1pt - Standard borders
    static let thin: CGFloat = 1.0

    /// 1.5pt - Medium borders
    static let regular: CGFloat = 1.5

    /// 2pt - Thick borders, focus rings
    static let thick: CGFloat = 2.0

    /// 3pt - Extra thick borders
    static let heavy: CGFloat = 3.0
}

// MARK: - Icon Size Tokens

enum IconSize {
    /// 12pt - Tiny icons (badges)
    static let tiny: CGFloat = 12

    /// 16pt - Small icons
    static let small: CGFloat = 16

    /// 20pt - Medium icons (inline)
    static let medium: CGFloat = 20

    /// 24pt - Large icons (buttons)
    static let large: CGFloat = 24

    /// 32pt - Extra large icons
    static let xl: CGFloat = 32

    /// 48pt - Hero icons
    static let xxl: CGFloat = 48
}

// MARK: - Z-Index Tokens

enum ZIndex {
    /// Background elements
    static let background: Double = 0

    /// Default content
    static let content: Double = 1

    /// Sticky headers
    static let sticky: Double = 10

    /// Floating elements
    static let floating: Double = 20

    /// Dropdowns, popovers
    static let dropdown: Double = 30

    /// Modals, sheets
    static let modal: Double = 40

    /// Toasts, notifications
    static let toast: Double = 50

    /// Tooltips
    static let tooltip: Double = 60
}

// MARK: - Duration Tokens (Animations)

enum Duration {
    /// 0.1s - Micro interactions
    static let instant: Double = 0.1

    /// 0.15s - Fast transitions
    static let fast: Double = 0.15

    /// 0.25s - Normal transitions
    static let normal: Double = 0.25

    /// 0.35s - Slow transitions
    static let slow: Double = 0.35

    /// 0.5s - Complex animations
    static let complex: Double = 0.5
}

// MARK: - Grid Tokens

enum GridTokens {
    /// Standard column count for photo grid
    static let photoGridColumns: Int = 2

    /// Minimum card width for adaptive grid
    static let minCardWidth: CGFloat = 150

    /// Maximum card width
    static let maxCardWidth: CGFloat = 300

    /// Aspect ratio for square thumbnails
    static let squareAspectRatio: CGFloat = 1.0

    /// Aspect ratio for 4:3 thumbnails
    static let landscapeAspectRatio: CGFloat = 4.0 / 3.0

    /// Aspect ratio for 3:4 thumbnails
    static let portraitAspectRatio: CGFloat = 3.0 / 4.0
}

// MARK: - Haptic Feedback

enum HapticStyle {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection

    #if os(iOS)
    func trigger() {
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
    #else
    func trigger() {
        // No haptics on macOS
    }
    #endif
}
