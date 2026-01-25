//
//  TagChip.swift
//  PhotoOrganizer
//
//  Tag chip component for displaying and managing tags
//

import SwiftUI

struct TagChip: View {
    let title: String
    let isSelected: Bool
    let showRemove: Bool
    let onTap: (() -> Void)?
    let onRemove: (() -> Void)?

    init(
        _ title: String,
        isSelected: Bool = false,
        showRemove: Bool = false,
        onTap: (() -> Void)? = nil,
        onRemove: (() -> Void)? = nil
    ) {
        self.title = title
        self.isSelected = isSelected
        self.showRemove = showRemove
        self.onTap = onTap
        self.onRemove = onRemove
    }

    var body: some View {
        HStack(spacing: Spacing.space1) {
            Text(title)
                .typography(.caption1, color: isSelected ? .ds.textOnAccent : .ds.textPrimary)
                .lineLimit(1)

            if showRemove {
                Button {
                    onRemove?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(isSelected ? Color.ds.textOnAccent.opacity(0.7) : Color.ds.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.space3)
        .padding(.vertical, Spacing.space2)
        .background(isSelected ? Color.ds.secondary : Color.ds.surfaceSecondary)
        .clipShape(Capsule())
        .contentShape(Capsule())
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Tag Chip Container

struct TagChipContainer: View {
    let tags: [String]
    let selectedTags: Set<String>
    let onTagTap: ((String) -> Void)?
    let onTagRemove: ((String) -> Void)?

    init(
        tags: [String],
        selectedTags: Set<String> = [],
        onTagTap: ((String) -> Void)? = nil,
        onTagRemove: ((String) -> Void)? = nil
    ) {
        self.tags = tags
        self.selectedTags = selectedTags
        self.onTagTap = onTagTap
        self.onTagRemove = onTagRemove
    }

    private let columns = [
        GridItem(.adaptive(minimum: 80), spacing: Spacing.space2)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.space2) {
            ForEach(tags, id: \.self) { tag in
                TagChip(
                    tag,
                    isSelected: selectedTags.contains(tag),
                    showRemove: onTagRemove != nil,
                    onTap: { onTagTap?(tag) },
                    onRemove: { onTagRemove?(tag) }
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 24) {
        // Basic chips
        HStack(spacing: 8) {
            TagChip("Nature")
            TagChip("Selected", isSelected: true)
            TagChip("Removable", showRemove: true)
        }

        // Container with multiple tags
        TagChipContainer(
            tags: ["Portrait", "Landscape", "Urban", "Nature", "Food", "Travel"],
            selectedTags: ["Nature", "Travel"],
            onTagTap: { _ in },
            onTagRemove: nil
        )

        // Container with remove buttons
        TagChipContainer(
            tags: ["Photo", "Camera", "Light"],
            selectedTags: [],
            onTagTap: nil,
            onTagRemove: { _ in }
        )
    }
    .padding()
    .background(Color.ds.background)
}
