//
//  GridLoadingOverlay.swift
//  PhotoOrganizer
//
//  Loading overlay for photo grid with progress indication
//

import SwiftUI

// MARK: - Grid Loading Overlay

struct GridLoadingOverlay: View {
    let message: String
    let progress: Double?

    init(_ message: String = "Loading...", progress: Double? = nil) {
        self.message = message
        self.progress = progress
    }

    var body: some View {
        VStack(spacing: Spacing.space4) {
            if let progress {
                ZStack {
                    Circle()
                        .stroke(Color.ds.border, lineWidth: 4)
                        .frame(width: 48, height: 48)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.ds.secondary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progress * 100))%")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.ds.secondary)
                }
            } else {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(Color.ds.secondary)
            }

            Text(message)
                .typography(.callout, color: .ds.textSecondary)
        }
        .padding(Spacing.space6)
        .background(Color.ds.surface.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
        .elevation(.high)
    }
}

// MARK: - Import Progress Overlay

struct ImportProgressOverlay: View {
    let current: Int
    let total: Int
    let onCancel: (() -> Void)?

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        VStack(spacing: Spacing.space4) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.ds.border, lineWidth: 6)
                    .frame(width: 64, height: 64)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.ds.secondary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: AnimationDuration.normal), value: progress)

                VStack(spacing: 0) {
                    Text("\(current)")
                        .font(.headline.bold())
                        .foregroundStyle(Color.ds.secondary)
                    Text("/\(total)")
                        .typography(.caption2, color: .ds.textTertiary)
                }
            }

            // Message
            VStack(spacing: Spacing.space1) {
                Text("Importing Photos")
                    .typography(.headline, color: .ds.textPrimary)

                Text("\(current) of \(total) completed")
                    .typography(.caption1, color: .ds.textSecondary)
            }

            // Cancel button
            if let onCancel {
                Button {
                    onCancel()
                } label: {
                    Text("Cancel")
                        .typography(.callout, color: .ds.error)
                }
                .buttonStyle(.plain)
                .padding(.top, Spacing.space2)
            }
        }
        .padding(Spacing.space6)
        .background(Color.ds.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
        .elevation(.high)
    }
}

// MARK: - Full Screen Loading

struct FullScreenLoading: View {
    let message: String

    var body: some View {
        ZStack {
            Color.ds.scrim
                .ignoresSafeArea()

            VStack(spacing: Spacing.space4) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text(message)
                    .typography(.headline, color: .white)
            }
            .padding(Spacing.space6)
            .background(Color.ds.surface.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
        }
    }
}

// MARK: - Preview

#Preview("Loading Overlays") {
    ZStack {
        Color.ds.background
            .ignoresSafeArea()

        VStack(spacing: 32) {
            GridLoadingOverlay("Loading photos...")

            GridLoadingOverlay("Importing...", progress: 0.65)

            ImportProgressOverlay(current: 7, total: 15, onCancel: {})
        }
    }
}
