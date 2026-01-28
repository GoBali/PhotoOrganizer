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
    let showInfo: Bool

    #if os(macOS)
    @State private var isHovered = false
    #endif

    init(
        image: Image?,
        label: String,
        location: String? = nil,
        status: PhotoCardStatus = .none,
        isLoading: Bool = false,
        showInfo: Bool = true
    ) {
        self.image = image
        self.label = label
        self.location = location
        self.status = status
        self.isLoading = isLoading
        self.showInfo = showInfo
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Image or placeholder
            imageContent
                #if os(macOS)
                .frame(minHeight: 100)  // macOS: 기존 높이
                #endif
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))

            // Glassmorphism overlay (조건부: showInfo가 true일 때만 표시)
            if showInfo {
                glassOverlay
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .elevation(currentElevation)
        #if os(macOS)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(Motion.spring(), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        #endif
        // iOS: DragGesture 제거 - ButtonStyle에서 피드백 처리
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
            #if os(iOS)
            // iOS: 4:3 비율 컨테이너에 이미지를 중앙 정렬하여 채움
            Color.clear
                .aspectRatio(4/3, contentMode: .fit)
                .overlay {
                    image
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
            #else
            // macOS: 기존 fit 모드 유지
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
            #endif
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

    /// 상태별 스타일 정보를 통합 제공
    var style: StatusStyle {
        switch self {
        case .none:
            return StatusStyle(
                text: "",
                backgroundColor: .clear,
                textColor: .clear,
                icon: nil,
                accessibilityText: ""
            )
        case .pending:
            return StatusStyle(
                text: "Pending",
                backgroundColor: Color.ds.warningBackground,
                textColor: Color.ds.warning,
                icon: "clock",
                accessibilityText: "Classification pending"
            )
        case .processing:
            return StatusStyle(
                text: "Classifying",
                backgroundColor: Color.ds.secondary.opacity(0.2),
                textColor: Color.ds.secondary,
                icon: "arrow.triangle.2.circlepath",
                accessibilityText: "Classification in progress"
            )
        case .completed(let confidence):
            return StatusStyle(
                text: String(format: "%.0f%%", confidence * 100),
                backgroundColor: Color.ds.successBackground,
                textColor: Color.ds.success,
                icon: "checkmark.circle.fill",
                accessibilityText: "Classified with \(Int(confidence * 100))% confidence"
            )
        case .failed:
            return StatusStyle(
                text: "Failed",
                backgroundColor: Color.ds.errorBackground,
                textColor: Color.ds.error,
                icon: "exclamationmark.circle.fill",
                accessibilityText: "Classification failed"
            )
        }
    }

    // MARK: - Convenience Accessors (style 통해 접근)

    var text: String { style.text }
    var backgroundColor: Color { style.backgroundColor }
    var textColor: Color { style.textColor }
    var icon: String? { style.icon }
    var accessibilityText: String { style.accessibilityText }
}

// MARK: - Status Style

struct StatusStyle {
    let text: String
    let backgroundColor: Color
    let textColor: Color
    let icon: String?
    let accessibilityText: String
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
