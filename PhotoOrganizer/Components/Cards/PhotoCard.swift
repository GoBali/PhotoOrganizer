//
//  PhotoCard.swift
//  PhotoOrganizer
//
//  Photo card component with glassmorphism overlay and touch feedback
//

import SwiftUI

struct PhotoCard: View {
    let image: Image?
    let label: String
    let location: String?
    let status: PhotoCardStatus
    let isLoading: Bool

    #if os(macOS)
    @State private var isHovered = false
    #endif
    @State private var isPressed = false

    init(
        image: Image?,
        label: String,
        location: String? = nil,
        status: PhotoCardStatus = .none,
        isLoading: Bool = false
    ) {
        self.image = image
        self.label = label
        self.location = location
        self.status = status
        self.isLoading = isLoading
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Image or placeholder
            imageContent
                .frame(minHeight: 100)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))

            // Glassmorphism overlay
            glassOverlay
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .elevation(currentElevation)
        #if os(macOS)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(Motion.spring(), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        #else
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .brightness(isPressed ? -0.03 : 0)
        .animation(Motion.springStiff(), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        HapticStyle.light.trigger()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        #endif
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Photo: \(label)")
        .accessibilityHint("Double tap to view details")
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(status.accessibilityText)
    }

    // MARK: - Image Content

    @ViewBuilder
    private var imageContent: some View {
        if let image {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Rectangle()
                .fill(Color.ds.surfaceSecondary)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if isLoading {
                        ProgressView()
                            .tint(Color.ds.textTertiary)
                    } else {
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundStyle(Color.ds.textTertiary)
                    }
                }
        }
    }

    // MARK: - Glass Overlay

    private var glassOverlay: some View {
        VStack(alignment: .leading, spacing: Spacing.space1) {
            Spacer()

            // Glass background with blur
            VStack(alignment: .leading, spacing: Spacing.space1) {
                // First row: Label + Status indicator
                HStack(spacing: Spacing.space1) {
                    Text(label)
                        .typography(.headline, color: .white)
                        .lineLimit(1)

                    Spacer()

                    if status != .none {
                        MinimalStatusIndicator(status: status)
                    }
                }

                // Second row: Location (if available)
                if let location, !location.isEmpty {
                    locationRow(location)
                }
            }
            .padding(.horizontal, Spacing.space3)
            .padding(.vertical, Spacing.space2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial.opacity(0.9))
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.3), Color.black.opacity(0.1)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
    }

    @ViewBuilder
    private func locationRow(_ location: String) -> some View {
        HStack(spacing: 4) {
            if location.hasPrefix("✨") {
                Text(location)
                    .typography(.caption1, color: .white.opacity(0.85))
                    .lineLimit(1)
            } else {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.85))
                Text(location)
                    .typography(.caption1, color: .white.opacity(0.85))
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Computed Properties

    private var currentElevation: Elevation {
        #if os(macOS)
        return isHovered ? .medium : .low
        #else
        return .low
        #endif
    }
}

// MARK: - Minimal Status Indicator

struct MinimalStatusIndicator: View {
    let status: PhotoCardStatus

    var body: some View {
        switch status {
        case .none:
            EmptyView()

        case .pending:
            Image(systemName: "clock")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.ds.warning)

        case .processing:
            ProgressView()
                .scaleEffect(0.5)
                .frame(width: 14, height: 14)
                .tint(.white)

        case .completed(let confidence):
            ConfidenceDot(confidence: confidence)

        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.ds.error)
        }
    }
}

// MARK: - Confidence Dot

struct ConfidenceDot: View {
    let confidence: Double

    private var color: Color {
        if confidence >= 0.8 {
            return Color.ds.success
        } else if confidence >= 0.5 {
            return Color.ds.warning
        } else {
            return Color.ds.error
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(String(format: "%.0f%%", confidence * 100))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.3))
        .clipShape(Capsule())
    }
}

// MARK: - Photo Card Status

enum PhotoCardStatus: Equatable {
    case none
    case pending
    case processing
    case completed(confidence: Double)
    case failed

    var text: String {
        switch self {
        case .none:
            return ""
        case .pending:
            return "Pending"
        case .processing:
            return "Classifying"
        case .completed(let confidence):
            return String(format: "%.0f%%", confidence * 100)
        case .failed:
            return "Failed"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .none:
            return .clear
        case .pending:
            return Color.ds.warningBackground
        case .processing:
            return Color.ds.secondary.opacity(0.2)
        case .completed:
            return Color.ds.successBackground
        case .failed:
            return Color.ds.errorBackground
        }
    }

    var textColor: Color {
        switch self {
        case .none:
            return .clear
        case .pending:
            return Color.ds.warning
        case .processing:
            return Color.ds.secondary
        case .completed:
            return Color.ds.success
        case .failed:
            return Color.ds.error
        }
    }

    var icon: String? {
        switch self {
        case .none: return nil
        case .pending: return "clock"
        case .processing: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        }
    }

    var accessibilityText: String {
        switch self {
        case .none: return ""
        case .pending: return "Classification pending"
        case .processing: return "Classification in progress"
        case .completed(let confidence): return "Classified with \(Int(confidence * 100))% confidence"
        case .failed: return "Classification failed"
        }
    }
}

// MARK: - Legacy Status Badge (for backwards compatibility)

struct PhotoCardStatusBadge: View {
    let status: PhotoCardStatus

    var body: some View {
        if status != .none {
            HStack(spacing: Spacing.space1) {
                if let icon = status.icon {
                    if status == .processing {
                        Image(systemName: icon)
                            .font(.system(size: IconSize.tiny, weight: .medium))
                            .rotationEffect(.degrees(status == .processing ? 360 : 0))
                            .animation(
                                status == .processing
                                    ? .linear(duration: 1.0).repeatForever(autoreverses: false)
                                    : .default,
                                value: status
                            )
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: IconSize.tiny, weight: .medium))
                    }
                }
                Text(status.text)
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(status.textColor)
            .padding(.horizontal, Spacing.space2)
            .padding(.vertical, Spacing.space1)
            .background(status.backgroundColor)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            PhotoCard(
                image: nil,
                label: "Loading...",
                status: .pending,
                isLoading: true
            )

            PhotoCard(
                image: Image(systemName: "photo.fill"),
                label: "Nature",
                location: "Seoul",
                status: .completed(confidence: 0.95)
            )

            PhotoCard(
                image: Image(systemName: "photo.fill"),
                label: "Processing",
                status: .processing
            )

            PhotoCard(
                image: Image(systemName: "photo.fill"),
                label: "Low Confidence",
                status: .completed(confidence: 0.45)
            )

            PhotoCard(
                image: Image(systemName: "photo.fill"),
                label: "Failed",
                status: .failed
            )

            PhotoCard(
                image: Image(systemName: "photo.fill"),
                label: "AI Location",
                location: "✨ Beach"
            )
        }
        .padding()
    }
    .background(Color.ds.background)
}
