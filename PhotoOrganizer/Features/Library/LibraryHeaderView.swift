//
//  LibraryHeaderView.swift
//  PhotoOrganizer
//
//  Header component for library view with title, search, and filters
//

import SwiftUI

struct LibraryHeaderView: View {
    let photoCount: Int
    let categories: [CategoryItem]
    @Binding var searchText: String
    @Binding var selectedCategory: String

    @State private var isSearchExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Title bar with photo count
            HStack {
                VStack(alignment: .leading, spacing: Spacing.space1) {
                    Text("Photo Organizer")
                        .typography(.title2, weight: .bold)

                    Text("\(photoCount) photos")
                        .typography(.caption1, color: .ds.textSecondary)
                }

                Spacer()

                // Theme toggle button
                ThemeToggleButton()
            }
            .padding(.horizontal, Spacing.space4)
            .padding(.top, Spacing.space4)
            .padding(.bottom, Spacing.space3)

            // Search bar (always visible)
            LibrarySearchBar(text: $searchText)
                .padding(.horizontal, Spacing.space4)
                .padding(.bottom, Spacing.space3)

            // Category filter bar
            CategoryFilterBar(categories: categories, selectedCategory: $selectedCategory)

            // Divider
            Divider()
                .background(Color.ds.border)
        }
        .background(Color.ds.surface)
    }
}

// MARK: - Compact Library Header

struct CompactLibraryHeader: View {
    let photoCount: Int
    @Binding var searchText: String

    var body: some View {
        VStack(spacing: Spacing.space2) {
            HStack {
                Text("Library")
                    .typography(.headline, weight: .semibold)

                Spacer()

                Text("\(photoCount)")
                    .typography(.caption1, color: .ds.textSecondary)
                    .padding(.horizontal, Spacing.space2)
                    .padding(.vertical, Spacing.space1)
                    .background(Color.ds.surfaceSecondary)
                    .clipShape(Capsule())
            }

            LibrarySearchBar(text: $searchText)
        }
        .padding(.horizontal, Spacing.space4)
        .padding(.vertical, Spacing.space3)
        .background(Color.ds.surface)
    }
}

// MARK: - Preview

#Preview("Library Header") {
    struct PreviewWrapper: View {
        @State private var searchText = ""
        @State private var selectedCategory = "All"

        let categories = [
            CategoryItem(name: "All", count: 42),
            CategoryItem(name: "Unclassified", count: 5),
            CategoryItem(name: "Nature", count: 15),
            CategoryItem(name: "Portrait", count: 8)
        ]

        var body: some View {
            VStack(spacing: 0) {
                LibraryHeaderView(
                    photoCount: 42,
                    categories: categories,
                    searchText: $searchText,
                    selectedCategory: $selectedCategory
                )

                Spacer()
            }
            .background(Color.ds.background)
        }
    }

    return PreviewWrapper()
}

#Preview("Compact Header") {
    struct PreviewWrapper: View {
        @State private var searchText = ""

        var body: some View {
            VStack(spacing: 0) {
                CompactLibraryHeader(photoCount: 42, searchText: $searchText)

                Spacer()
            }
            .background(Color.ds.background)
        }
    }

    return PreviewWrapper()
}
