//
//  ErrorStateView.swift
//  PhotoOrganizer
//
//  Error state display component
//

import SwiftUI

struct ErrorStateView: View {
    let icon: String
    let title: String
    let message: String
    let retryTitle: String?
    let onRetry: (() -> Void)?

    init(
        icon: String = "exclamationmark.triangle",
        title: String = "Something Went Wrong",
        message: String,
        retryTitle: String? = "Try Again",
        onRetry: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(spacing: Spacing.space4) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(Color.ds.error)

            VStack(spacing: Spacing.space2) {
                Text(title)
                    .typography(.title3, color: .ds.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .typography(.body, color: .ds.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let retryTitle, let onRetry {
                Button(retryTitle, action: onRetry)
                    .primaryButtonStyle()
                    .frame(maxWidth: 200)
                    .padding(.top, Spacing.space2)
            }
        }
        .padding(Spacing.space5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error Banner (Inline)

struct ErrorBanner: View {
    let message: String
    let onDismiss: (() -> Void)?

    init(_ message: String, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(spacing: Spacing.space3) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.body)
                .foregroundStyle(Color.ds.error)

            Text(message)
                .typography(.callout, color: .ds.error)
                .lineLimit(2)

            Spacer()

            if let onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(Color.ds.error)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.space3)
        .background(Color.ds.errorBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
}

// MARK: - Preset Error States

extension ErrorStateView {
    /// Generic error
    static func generic(onRetry: (() -> Void)? = nil) -> ErrorStateView {
        ErrorStateView(
            message: "An unexpected error occurred. Please try again.",
            onRetry: onRetry
        )
    }

    /// Import failed
    static func importFailed(onRetry: (() -> Void)? = nil) -> ErrorStateView {
        ErrorStateView(
            icon: "photo.badge.exclamationmark",
            title: "Import Failed",
            message: "Failed to import one or more photos. Please check the file format and try again.",
            onRetry: onRetry
        )
    }

    /// Classification failed
    static func classificationFailed(onRetry: (() -> Void)? = nil) -> ErrorStateView {
        ErrorStateView(
            icon: "cpu",
            title: "Classification Failed",
            message: "Unable to classify the photo. The ML model may not be available.",
            onRetry: onRetry
        )
    }
}

// MARK: - Preview

#Preview("Full Screen Error") {
    ErrorStateView.generic {}
        .background(Color.ds.background)
}

#Preview("Import Error") {
    ErrorStateView.importFailed {}
        .background(Color.ds.background)
}

#Preview("Error Banner") {
    VStack {
        ErrorBanner("Failed to save changes.") {}
        Spacer()
    }
    .padding()
    .background(Color.ds.background)
}
