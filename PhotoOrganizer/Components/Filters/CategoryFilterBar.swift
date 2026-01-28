//
//  CategoryFilterBar.swift
//  PhotoOrganizer
//
//  Horizontal scrolling category filter bar
//

import SwiftUI

struct CategoryFilterBar: View {
    let categories: [CategoryItem]
    @Binding var selectedCategory: String
    var showIcons: Bool = false

    init(categories: [CategoryItem], selectedCategory: Binding<String>, showIcons: Bool = false) {
        self.categories = categories
        self._selectedCategory = selectedCategory
        self.showIcons = showIcons
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.space2) {
                ForEach(categories) { category in
                    categoryChip(for: category)
                }
            }
            #if os(iOS)
            .padding(.horizontal, Spacing.space2)  // iOS: 8pt (더 많은 필터 표시)
            #else
            .padding(.horizontal, Spacing.space4)  // macOS: 16pt
            #endif
            .padding(.vertical, Spacing.space2)
        }
    }

    @ViewBuilder
    private func categoryChip(for category: CategoryItem) -> some View {
        let isSelected = selectedCategory == category.name
        let action = {
            withAnimation(.easeInOut(duration: AnimationDuration.fast)) {
                selectedCategory = category.name
            }
        }

        if showIcons, let icon = category.icon {
            CategoryChipWithIcon(
                category.name,
                icon: icon,
                count: category.count,
                isSelected: isSelected,
                action: action
            )
        } else {
            CategoryChip(
                category.name,
                count: category.count,
                isSelected: isSelected,
                action: action
            )
        }
    }
}

// MARK: - Category Item

struct CategoryItem: Identifiable, Equatable {
    let id: String
    let name: String
    let count: Int
    let icon: String?

    init(name: String, count: Int = 0, icon: String? = nil) {
        self.id = name
        self.name = name
        self.count = count
        self.icon = icon
    }

    static func == (lhs: CategoryItem, rhs: CategoryItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preview

#Preview("Category Filter Bar") {
    struct PreviewWrapper: View {
        @State private var selected = "All"

        let categories = [
            CategoryItem(name: "All", count: 42, icon: "photo.on.rectangle"),
            CategoryItem(name: "Unclassified", count: 5, icon: "questionmark.circle"),
            CategoryItem(name: "Nature", count: 15, icon: "leaf"),
            CategoryItem(name: "Portrait", count: 8),
            CategoryItem(name: "Urban", count: 7),
            CategoryItem(name: "Food", count: 4),
            CategoryItem(name: "Travel", count: 3)
        ]

        var body: some View {
            VStack(spacing: 24) {
                Text("Without Icons")
                    .typography(.caption1)
                CategoryFilterBar(categories: categories, selectedCategory: $selected)

                Text("With Icons")
                    .typography(.caption1)
                CategoryFilterBar(categories: categories, selectedCategory: $selected, showIcons: true)

                Text("Selected: \(selected)")
                    .typography(.body)
            }
            .background(Color.ds.background)
        }
    }

    return PreviewWrapper()
}
