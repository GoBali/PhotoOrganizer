//
//  SectionCard.swift
//  PhotoOrganizer
//
//  Section card component for grouping content
//

import SwiftUI

struct SectionCard<Content: View>: View {
    let title: String?
    let subtitle: String?
    let content: Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.space3) {
            if title != nil || subtitle != nil {
                VStack(alignment: .leading, spacing: Spacing.space1) {
                    if let title {
                        Text(title)
                            .typography(.headline, color: .ds.textPrimary)
                    }
                    if let subtitle {
                        Text(subtitle)
                            .typography(.callout, color: .ds.textSecondary)
                    }
                }
            }

            content
        }
        .sectionCard()
    }
}

// MARK: - Inline Section Card (without card background)

struct InlineSectionHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionLabel: String?

    init(
        _ title: String,
        subtitle: String? = nil,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionLabel = actionLabel
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: Spacing.space1) {
                Text(title)
                    .typography(.title3, color: .ds.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .typography(.callout, color: .ds.textSecondary)
                }
            }

            Spacer()

            if let action, let actionLabel {
                Button(actionLabel, action: action)
                    .typography(.callout, color: .ds.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            // Section card with title and content
            SectionCard(title: "Photo Details", subtitle: "Classification result") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Label:")
                            .typography(.body, color: .ds.textSecondary)
                        Text("Nature")
                            .typography(.body, color: .ds.textPrimary)
                    }
                    HStack {
                        Text("Confidence:")
                            .typography(.body, color: .ds.textSecondary)
                        Text("95%")
                            .typography(.body, color: .ds.success)
                    }
                }
            }

            // Section card without header
            SectionCard {
                Text("Content only card")
                    .typography(.body, color: .ds.textPrimary)
            }

            // Inline section header
            InlineSectionHeader(
                "Recent Photos",
                subtitle: "Last 7 days",
                actionLabel: "See All"
            ) {}
        }
        .padding()
    }
    .background(Color.ds.background)
}
