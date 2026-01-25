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

    init(categories: [CategoryItem], selectedCategory: Binding<String>) {
        self.categories = categories
        self._selectedCategory = selectedCategory
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.space2) {
                ForEach(categories) { category in
                    CategoryChip(
                        category.name,
                        count: category.count,
                        isSelected: selectedCategory == category.name
                    ) {
                        withAnimation(.easeInOut(duration: AnimationDuration.fast)) {
                            selectedCategory = category.name
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.space4)
            .padding(.vertical, Spacing.space2)
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

// MARK: - Category Filter Bar with Icons

struct CategoryFilterBarWithIcons: View {
    let categories: [CategoryItem]
    @Binding var selectedCategory: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.space2) {
                ForEach(categories) { category in
                    if let icon = category.icon {
                        CategoryChipWithIcon(
                            category.name,
                            icon: icon,
                            count: category.count,
                            isSelected: selectedCategory == category.name
                        ) {
                            withAnimation(.easeInOut(duration: AnimationDuration.fast)) {
                                selectedCategory = category.name
                            }
                        }
                    } else {
                        CategoryChip(
                            category.name,
                            count: category.count,
                            isSelected: selectedCategory == category.name
                        ) {
                            withAnimation(.easeInOut(duration: AnimationDuration.fast)) {
                                selectedCategory = category.name
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.space4)
            .padding(.vertical, Spacing.space2)
        }
    }
}

// MARK: - Preview

#Preview("Category Filter Bar") {
    struct PreviewWrapper: View {
        @State private var selected = "All"

        let categories = [
            CategoryItem(name: "All", count: 42),
            CategoryItem(name: "Unclassified", count: 5),
            CategoryItem(name: "Nature", count: 15),
            CategoryItem(name: "Portrait", count: 8),
            CategoryItem(name: "Urban", count: 7),
            CategoryItem(name: "Food", count: 4),
            CategoryItem(name: "Travel", count: 3)
        ]

        var body: some View {
            VStack(spacing: 24) {
                CategoryFilterBar(categories: categories, selectedCategory: $selected)

                Text("Selected: \(selected)")
                    .typography(.body)
            }
            .background(Color.ds.background)
        }
    }

    return PreviewWrapper()
}
