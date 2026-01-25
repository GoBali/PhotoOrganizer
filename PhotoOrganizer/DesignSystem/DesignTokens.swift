//
//  DesignTokens.swift
//  PhotoOrganizer
//
//  Design system foundation - Colors, Spacing, Corner Radii, Shadows
//  Supports light and dark mode automatically via ColorScheme-aware colors
//

import SwiftUI

// MARK: - Color Tokens

extension Color {
    static let ds = DesignColors()
}

struct DesignColors {
    // MARK: - Primary & Accent (Dark mode aware)

    /// Deep navy in light, light gray in dark - titles, primary text
    let primary = Color(light: Color(hex: "1A1A2E"), dark: Color(hex: "E8E8F0"))

    /// Indigo - accent, buttons, active states (slightly brighter in dark mode)
    let secondary = Color(light: Color(hex: "6366F1"), dark: Color(hex: "818CF8"))

    /// Accent variant for hover/pressed states
    let secondaryVariant = Color(light: Color(hex: "4F46E5"), dark: Color(hex: "A5B4FC"))

    // MARK: - Neutral (Dark mode aware)

    /// App background
    let background = Color(light: Color(hex: "FAFBFC"), dark: Color(hex: "0F0F14"))

    /// Cards, elevated content
    let surface = Color(light: .white, dark: Color(hex: "1C1C24"))

    /// Secondary surface - input field backgrounds
    let surfaceSecondary = Color(light: Color(hex: "F4F5F7"), dark: Color(hex: "26262F"))

    /// Tertiary surface - subtle backgrounds
    let surfaceTertiary = Color(light: Color(hex: "E5E7EB"), dark: Color(hex: "2F2F3A"))

    /// Dividers, card borders
    let border = Color(light: Color(hex: "E5E7EB"), dark: Color(hex: "3A3A46"))

    /// Subtle dividers
    let borderSubtle = Color(light: Color(hex: "F3F4F6"), dark: Color(hex: "2A2A35"))

    // MARK: - Text (Dark mode aware)

    /// Body text
    let textPrimary = Color(light: Color(hex: "1F2937"), dark: Color(hex: "F3F4F6"))

    /// Secondary text
    let textSecondary = Color(light: Color(hex: "6B7280"), dark: Color(hex: "9CA3AF"))

    /// Disabled/tertiary text
    let textTertiary = Color(light: Color(hex: "9CA3AF"), dark: Color(hex: "6B7280"))

    /// Text on accent color backgrounds
    let textOnAccent = Color.white

    /// Inverted text (for badges, etc.)
    let textInverted = Color(light: .white, dark: Color(hex: "1A1A2E"))

    // MARK: - Semantic - Success (Dark mode aware)

    let success = Color(light: Color(hex: "10B981"), dark: Color(hex: "34D399"))
    let successBackground = Color(light: Color(hex: "ECFDF5"), dark: Color(hex: "064E3B"))

    // MARK: - Semantic - Warning (Dark mode aware)

    let warning = Color(light: Color(hex: "F59E0B"), dark: Color(hex: "FBBF24"))
    let warningBackground = Color(light: Color(hex: "FFFBEB"), dark: Color(hex: "78350F"))

    // MARK: - Semantic - Error (Dark mode aware)

    let error = Color(light: Color(hex: "EF4444"), dark: Color(hex: "F87171"))
    let errorBackground = Color(light: Color(hex: "FEF2F2"), dark: Color(hex: "7F1D1D"))

    // MARK: - Semantic - Info (Dark mode aware)

    let info = Color(light: Color(hex: "3B82F6"), dark: Color(hex: "60A5FA"))
    let infoBackground = Color(light: Color(hex: "EFF6FF"), dark: Color(hex: "1E3A5F"))

    // MARK: - Overlay & Scrim

    /// For modal overlays
    let scrim = Color.black.opacity(0.4)

    /// For image overlays (gradients)
    let imageOverlay = Color.black.opacity(0.4)
}

// MARK: - Color Extension for Light/Dark Mode

extension Color {
    /// Creates a color that adapts to light/dark mode
    init(light: Color, dark: Color) {
        #if os(iOS)
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
        #elseif os(macOS)
        self.init(NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(dark)
            } else {
                return NSColor(light)
            }
        })
        #endif
    }
}

// MARK: - Spacing Tokens (8pt Grid)

enum Spacing {
    /// 4pt - Inline small gap
    static let space1: CGFloat = 4
    /// 8pt - Default inline
    static let space2: CGFloat = 8
    /// 12pt - Stack, grid gap
    static let space3: CGFloat = 12
    /// 16pt - Section padding
    static let space4: CGFloat = 16
    /// 20pt - Screen padding
    static let space5: CGFloat = 20
    /// 24pt - Section gap
    static let space6: CGFloat = 24
    /// 32pt - Large section gap
    static let space7: CGFloat = 32
}

// MARK: - Corner Radius Tokens

enum CornerRadius {
    /// 6pt - Badges, chips
    static let small: CGFloat = 6
    /// 10pt - Buttons, inputs
    static let medium: CGFloat = 10
    /// 14pt - Cards, images
    static let large: CGFloat = 14
    /// 20pt - Sheets, panels
    static let xl: CGFloat = 20
}

// MARK: - Shadow Tokens

struct Elevation {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    /// Low elevation - subtle shadow for cards
    static let low = Elevation(
        color: Color.black.opacity(0.05),
        radius: 2,
        x: 0,
        y: 1
    )

    /// Medium elevation - buttons, floating elements
    static let medium = Elevation(
        color: Color.black.opacity(0.07),
        radius: 6,
        x: 0,
        y: 4
    )

    /// High elevation - modals, overlays
    static let high = Elevation(
        color: Color.black.opacity(0.1),
        radius: 15,
        x: 0,
        y: 10
    )
}

// MARK: - Size Tokens

enum ComponentSize {
    /// 44pt - Minimum tap target
    static let minTapTarget: CGFloat = 44
    /// 48pt - Standard button height
    static let buttonHeight: CGFloat = 48
    /// 48pt - Standard input height
    static let inputHeight: CGFloat = 48
    /// 36pt - Small button height
    static let buttonHeightSmall: CGFloat = 36
}

// MARK: - Animation Tokens

enum AnimationDuration {
    static let fast: Double = 0.15
    static let normal: Double = 0.25
    static let slow: Double = 0.35
}

// MARK: - Motion Tokens (Unified Animation System)

enum Motion {
    /// 0.1s - Micro interactions
    static let instant: Double = 0.1
    /// 0.15s - Fast transitions
    static let fast: Double = 0.15
    /// 0.25s - Normal transitions
    static let normal: Double = 0.25
    /// 0.35s - Slow transitions
    static let slow: Double = 0.35

    /// Standard spring animation for interactive elements
    static func spring() -> Animation {
        .spring(response: 0.3, dampingFraction: 0.7)
    }

    /// Bouncy spring for playful feedback
    static func springBouncy() -> Animation {
        .spring(response: 0.35, dampingFraction: 0.6)
    }

    /// Stiff spring for quick snaps
    static func springStiff() -> Animation {
        .spring(response: 0.2, dampingFraction: 0.8)
    }

    /// Smooth easing for state changes
    static func smooth() -> Animation {
        .easeInOut(duration: normal)
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extension for Elevation

extension View {
    func elevation(_ elevation: Elevation) -> some View {
        self.shadow(
            color: elevation.color,
            radius: elevation.radius,
            x: elevation.x,
            y: elevation.y
        )
    }
}
