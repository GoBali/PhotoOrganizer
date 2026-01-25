//
//  ClassificationHeroCard.swift
//  PhotoOrganizer
//
//  Hero card for displaying classification results prominently
//

import SwiftUI

struct ClassificationHeroCard: View {
    let label: String
    let confidence: Double
    let status: ClassificationState
    let isProcessing: Bool
    let onReclassify: () -> Void

    init(
        label: String,
        confidence: Double,
        status: ClassificationState,
        isProcessing: Bool = false,
        onReclassify: @escaping () -> Void
    ) {
        self.label = label
        self.confidence = confidence
        self.status = status
        self.isProcessing = isProcessing
        self.onReclassify = onReclassify
    }

    private var categoryIcon: String {
        let lowercased = label.lowercased()

        // Beach
        if ["beach", "shore", "coast", "seashore", "ocean", "sea"].contains(where: { lowercased.contains($0) }) {
            return "sun.horizon.fill"
        }
        // Mountain
        if ["mountain", "hill", "canyon", "cliff", "valley", "alp", "volcano"].contains(where: { lowercased.contains($0) }) {
            return "mountain.2.fill"
        }
        // Forest
        if ["forest", "jungle", "woodland", "tree", "rainforest", "park", "garden"].contains(where: { lowercased.contains($0) }) {
            return "leaf.fill"
        }
        // City
        if ["city", "street", "building", "urban", "downtown", "skyscraper", "bridge"].contains(where: { lowercased.contains($0) }) {
            return "building.2.fill"
        }
        // Lake/Water
        if ["lake", "river", "waterfall", "pond", "stream", "reservoir", "water"].contains(where: { lowercased.contains($0) }) {
            return "drop.fill"
        }
        // Indoor
        if ["restaurant", "cafe", "museum", "hotel", "room", "indoor", "interior"].contains(where: { lowercased.contains($0) }) {
            return "house.fill"
        }
        // Animal
        if ["dog", "cat", "bird", "animal", "pet", "wildlife"].contains(where: { lowercased.contains($0) }) {
            return "pawprint.fill"
        }
        // Food
        if ["food", "meal", "dish", "restaurant", "pizza", "burger"].contains(where: { lowercased.contains($0) }) {
            return "fork.knife"
        }
        // Person
        if ["person", "people", "portrait", "selfie", "face"].contains(where: { lowercased.contains($0) }) {
            return "person.fill"
        }
        // Default
        return "photo.fill"
    }

    private var gradientColors: [Color] {
        switch status {
        case .completed:
            return [Color.ds.secondary.opacity(0.15), Color.ds.secondary.opacity(0.05)]
        case .failed:
            return [Color.ds.error.opacity(0.15), Color.ds.error.opacity(0.05)]
        case .processing:
            return [Color.ds.info.opacity(0.15), Color.ds.info.opacity(0.05)]
        case .pending:
            return [Color.ds.warning.opacity(0.15), Color.ds.warning.opacity(0.05)]
        }
    }

    var body: some View {
        VStack(spacing: Spacing.space3) {
            // Main content
            HStack(alignment: .center, spacing: Spacing.space4) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(Color.ds.secondary.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: categoryIcon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.ds.secondary)
                }

                // Label and confidence
                VStack(alignment: .leading, spacing: Spacing.space1) {
                    Text(label)
                        .typography(.title3, color: .ds.textPrimary)
                        .lineLimit(2)

                    if status == .completed {
                        ConfidenceBadge(confidence: confidence, size: .medium)
                    } else if status == .processing || isProcessing {
                        HStack(spacing: Spacing.space2) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Classifying...")
                                .typography(.caption1, color: .ds.textSecondary)
                        }
                    } else if status == .failed {
                        HStack(spacing: Spacing.space1) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text("Classification failed")
                                .typography(.caption1)
                        }
                        .foregroundStyle(Color.ds.error)
                    } else if status == .pending {
                        Text("Pending classification")
                            .typography(.caption1, color: .ds.textTertiary)
                    }
                }

                Spacer()

                // Reclassify button
                Button(action: onReclassify) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.ds.secondary)
                        .frame(width: 40, height: 40)
                        .background(Color.ds.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isProcessing || status == .processing)
                .opacity(isProcessing || status == .processing ? 0.5 : 1)
            }
        }
        .padding(Spacing.space4)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(Color.ds.border, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Classification Hero Card") {
    ScrollView {
        VStack(spacing: Spacing.space4) {
            ClassificationHeroCard(
                label: "Beach",
                confidence: 0.95,
                status: .completed
            ) { }

            ClassificationHeroCard(
                label: "Mountain landscape",
                confidence: 0.78,
                status: .completed
            ) { }

            ClassificationHeroCard(
                label: "Unclassified",
                confidence: 0.0,
                status: .processing
            ) { }

            ClassificationHeroCard(
                label: "Unclassified",
                confidence: 0.0,
                status: .failed
            ) { }

            ClassificationHeroCard(
                label: "Unclassified",
                confidence: 0.0,
                status: .pending
            ) { }
        }
        .padding()
    }
    .background(Color.ds.background)
}
