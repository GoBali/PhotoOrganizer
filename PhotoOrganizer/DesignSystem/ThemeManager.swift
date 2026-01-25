//
//  ThemeManager.swift
//  PhotoOrganizer
//
//  Manages app theme (light/dark/system) with persistence
//

import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

// MARK: - Theme Manager

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("app_theme") private(set) var selectedTheme: AppTheme = .system

    /// Returns the color scheme to apply, or nil to follow system
    var preferredColorScheme: ColorScheme? {
        switch selectedTheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// Check if currently in dark mode
    var isDarkMode: Bool {
        switch selectedTheme {
        case .system:
            #if os(iOS)
            return UITraitCollection.current.userInterfaceStyle == .dark
            #elseif os(macOS)
            return NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            #endif
        case .light:
            return false
        case .dark:
            return true
        }
    }

    func setTheme(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: AnimationDuration.normal)) {
            selectedTheme = theme
        }
        objectWillChange.send()
    }

    private init() {}
}

// MARK: - Theme Modifier

struct ThemeModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.preferredColorScheme)
    }
}

extension View {
    /// Applies the app's theme preference
    func applyTheme() -> some View {
        modifier(ThemeModifier())
    }
}

// MARK: - Theme Picker View

struct ThemePicker: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        Picker("Theme", selection: Binding(
            get: { themeManager.selectedTheme },
            set: { themeManager.setTheme($0) }
        )) {
            ForEach(AppTheme.allCases) { theme in
                Label(theme.displayName, systemImage: theme.icon)
                    .tag(theme)
            }
        }
    }
}

// MARK: - Theme Toggle Button

struct ThemeToggleButton: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button {
            let themes = AppTheme.allCases
            if let currentIndex = themes.firstIndex(of: themeManager.selectedTheme) {
                let nextIndex = (currentIndex + 1) % themes.count
                themeManager.setTheme(themes[nextIndex])
            }
        } label: {
            Image(systemName: themeManager.selectedTheme.icon)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.ds.secondary)
                .frame(width: ComponentSize.minTapTarget, height: ComponentSize.minTapTarget)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Theme: \(themeManager.selectedTheme.displayName)")
        .accessibilityHint("Double tap to cycle through themes")
    }
}
