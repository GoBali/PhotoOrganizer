//
//  ButtonStyles.swift
//  PhotoOrganizer
//
//  Custom button styles for the design system
//

import SwiftUI

// MARK: - Primary Button Style

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .typography(.headline, color: .ds.textOnAccent)
            .frame(maxWidth: .infinity)
            .frame(height: ComponentSize.buttonHeight)
            .background(isEnabled ? Color.ds.secondary : Color.ds.secondary.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.fast), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .typography(.headline, color: isEnabled ? .ds.secondary : .ds.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: ComponentSize.buttonHeight)
            .background(Color.ds.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .stroke(isEnabled ? Color.ds.secondary : Color.ds.border, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.fast), value: configuration.isPressed)
    }
}

// MARK: - Icon Button Style

struct IconButtonStyle: ButtonStyle {
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color

    init(
        size: CGFloat = ComponentSize.minTapTarget,
        backgroundColor: Color = Color.ds.surfaceSecondary,
        foregroundColor: Color = Color.ds.textPrimary
    ) {
        self.size = size
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor)
            .frame(width: size, height: size)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.fast), value: configuration.isPressed)
    }
}

// MARK: - Destructive Button Style

struct DestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .typography(.headline, color: .ds.textOnAccent)
            .frame(maxWidth: .infinity)
            .frame(height: ComponentSize.buttonHeight)
            .background(isEnabled ? Color.ds.error : Color.ds.error.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.fast), value: configuration.isPressed)
    }
}

// MARK: - Tag Chip Style

struct TagChipStyle: ButtonStyle {
    let isSelected: Bool

    init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .typography(.caption1, color: isSelected ? .ds.textOnAccent : .ds.textPrimary)
            .padding(.horizontal, Spacing.space3)
            .padding(.vertical, Spacing.space2)
            .background(isSelected ? Color.ds.secondary : Color.ds.surfaceSecondary)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.fast), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func primaryButtonStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }

    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }

    func iconButtonStyle(
        size: CGFloat = ComponentSize.minTapTarget,
        backgroundColor: Color = Color.ds.surfaceSecondary,
        foregroundColor: Color = Color.ds.textPrimary
    ) -> some View {
        self.buttonStyle(IconButtonStyle(
            size: size,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        ))
    }

    func destructiveButtonStyle() -> some View {
        self.buttonStyle(DestructiveButtonStyle())
    }

    func tagChipStyle(isSelected: Bool = false) -> some View {
        self.buttonStyle(TagChipStyle(isSelected: isSelected))
    }
}

// MARK: - Preview

#Preview("Button Styles") {
    VStack(spacing: 24) {
        Button("Primary Button") {}
            .primaryButtonStyle()

        Button("Secondary Button") {}
            .secondaryButtonStyle()

        Button("Destructive Button") {}
            .destructiveButtonStyle()

        Button("Disabled Primary") {}
            .primaryButtonStyle()
            .disabled(true)

        HStack(spacing: 16) {
            Button {
            } label: {
                Image(systemName: "plus")
                    .font(.body.bold())
            }
            .iconButtonStyle()

            Button {
            } label: {
                Image(systemName: "trash")
                    .font(.body.bold())
            }
            .iconButtonStyle(
                backgroundColor: Color.ds.errorBackground,
                foregroundColor: Color.ds.error
            )
        }

        HStack(spacing: 8) {
            Button("Nature") {}
                .tagChipStyle(isSelected: true)
            Button("Portrait") {}
                .tagChipStyle()
            Button("Urban") {}
                .tagChipStyle()
        }
    }
    .padding()
    .background(Color.ds.background)
}
