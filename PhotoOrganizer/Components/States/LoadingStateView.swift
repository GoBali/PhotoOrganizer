//
//  LoadingStateView.swift
//  PhotoOrganizer
//
//  Loading state indicator component
//

import SwiftUI

struct LoadingStateView: View {
    let message: String?

    init(_ message: String? = nil) {
        self.message = message
    }

    var body: some View {
        VStack(spacing: Spacing.space3) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.ds.secondary)

            if let message {
                Text(message)
                    .typography(.callout, color: .ds.textSecondary)
            }
        }
        .padding(Spacing.space5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Inline Loading Indicator

struct LoadingIndicator: View {
    let message: String?
    let style: LoadingIndicatorStyle

    enum LoadingIndicatorStyle {
        case inline
        case overlay
        case toast
    }

    init(_ message: String? = nil, style: LoadingIndicatorStyle = .inline) {
        self.message = message
        self.style = style
    }

    var body: some View {
        Group {
            switch style {
            case .inline:
                inlineView
            case .overlay:
                overlayView
            case .toast:
                toastView
            }
        }
    }

    private var inlineView: some View {
        HStack(spacing: Spacing.space2) {
            ProgressView()
                .scaleEffect(0.9)
                .tint(Color.ds.secondary)

            if let message {
                Text(message)
                    .typography(.callout, color: .ds.textSecondary)
            }
        }
    }

    private var overlayView: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: Spacing.space3) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)

                if let message {
                    Text(message)
                        .typography(.callout, color: .white)
                }
            }
            .padding(Spacing.space5)
            .background(Color.ds.textPrimary.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        }
    }

    private var toastView: some View {
        HStack(spacing: Spacing.space2) {
            ProgressView()
                .scaleEffect(0.85)
                .tint(Color.ds.textPrimary)

            if let message {
                Text(message)
                    .typography(.callout, color: .ds.textPrimary)
            }
        }
        .padding(.horizontal, Spacing.space4)
        .padding(.vertical, Spacing.space3)
        .background(Color.ds.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .elevation(.medium)
    }
}

// MARK: - Preview

#Preview("Full Screen Loading") {
    LoadingStateView("Loading photos...")
        .background(Color.ds.background)
}

#Preview("Loading Indicators") {
    VStack(spacing: 32) {
        LoadingIndicator("Importing...", style: .inline)

        LoadingIndicator("Processing...", style: .toast)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.ds.background)
}

#Preview("Overlay") {
    ZStack {
        Color.ds.background
            .ignoresSafeArea()

        Text("Background content")
            .typography(.title1, color: .ds.textPrimary)

        LoadingIndicator("Saving...", style: .overlay)
    }
}
