//
//  EmptyStateView.swift
//  PhotoOrganizer
//
//  Empty state placeholder with animated illustration
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?

    @State private var isPulsing = false
    @State private var isAnimating = false

    init(
        icon: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Spacing.space5) {
            // Animated illustration
            illustrationView
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                    withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }

            // Text content
            VStack(spacing: Spacing.space2) {
                Text(title)
                    .typography(.title3, color: .ds.textPrimary)
                    .multilineTextAlignment(.center)

                Text(description)
                    .typography(.body, color: .ds.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // CTA Button
            if let actionTitle, let action {
                ctaButton(title: actionTitle, action: action)
            }
        }
        .padding(.horizontal, Spacing.space5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Illustration

    private var illustrationView: some View {
        ZStack {
            // Outer circle
            Circle()
                .fill(Color.ds.secondary.opacity(0.05))
                .frame(width: 160, height: 160)
                .scaleEffect(isPulsing ? 1.1 : 1.0)

            // Middle circle
            Circle()
                .fill(Color.ds.secondary.opacity(0.08))
                .frame(width: 120, height: 120)
                .scaleEffect(isPulsing ? 1.05 : 0.95)

            // Inner circle
            Circle()
                .fill(Color.ds.secondary.opacity(0.12))
                .frame(width: 80, height: 80)

            // Icon with pulse effect
            Image(systemName: icon)
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(Color.ds.secondary)
                .scaleEffect(isAnimating ? 1.1 : 0.95)
                .opacity(isAnimating ? 1.0 : 0.7)
        }
    }

    // MARK: - CTA Button

    private func ctaButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.space2) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: IconSize.medium, weight: .semibold))

                Text(title)
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(Color.ds.textOnAccent)
            .padding(.horizontal, Spacing.space5)
            .padding(.vertical, Spacing.space3)
            .background(
                LinearGradient(
                    colors: [Color.ds.secondary, Color.ds.secondaryVariant],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .elevation(.medium)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.top, Spacing.space3)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(Motion.springStiff(), value: configuration.isPressed)
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    /// Empty photo library
    static func noPhotos(action: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "photo.on.rectangle.angled",
            title: "No Photos Yet",
            description: "Import photos to start organizing your collection with AI-powered classification.",
            actionTitle: action != nil ? "Import Photos" : nil,
            action: action
        )
    }

    /// No search results
    static func noResults(searchText: String) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            description: "No photos match \"\(searchText)\". Try a different search term or check your spelling."
        )
    }

    /// No photos in category
    static func noPhotosInCategory(category: String) -> EmptyStateView {
        EmptyStateView(
            icon: "folder",
            title: "Empty Category",
            description: "No photos in \"\(category)\" yet. Import more photos to see them here."
        )
    }
}

// MARK: - Preview

#Preview("No Photos") {
    VStack {
        EmptyStateView.noPhotos {}
    }
    .background(Color.ds.background)
}

#Preview("No Results") {
    VStack {
        EmptyStateView.noResults(searchText: "sunset beach")
    }
    .background(Color.ds.background)
}

#Preview("Empty Category") {
    VStack {
        EmptyStateView.noPhotosInCategory(category: "Nature")
    }
    .background(Color.ds.background)
}
