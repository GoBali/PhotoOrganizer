//
//  LibrarySearchBar.swift
//  PhotoOrganizer
//
//  Always-visible search bar for library view
//

import SwiftUI

struct LibrarySearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.space2) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: IconSize.medium, weight: .medium))
                .foregroundStyle(isFocused ? Color.ds.secondary : Color.ds.textTertiary)

            TextField("Search tags, notes, or labels...", text: $text)
                .typography(.body, color: .ds.textPrimary)
                .focused($isFocused)
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: AnimationDuration.fast)) {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: IconSize.medium))
                        .foregroundStyle(Color.ds.textTertiary)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, Spacing.space3)
        .frame(height: ComponentSize.inputHeight)
        .background(Color.ds.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .stroke(isFocused ? Color.ds.secondary : Color.clear, lineWidth: BorderWidth.thick)
        )
        .animation(.easeInOut(duration: AnimationDuration.fast), value: isFocused)
        .animation(.easeInOut(duration: AnimationDuration.fast), value: text.isEmpty)
        .accessibilityLabel("Search photos")
        .accessibilityHint("Enter keywords to filter photos by tags, notes, or classification labels")
    }
}

// MARK: - Expandable Search Bar

struct ExpandableSearchBar: View {
    @Binding var text: String
    @State private var isExpanded = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.space2) {
            if isExpanded {
                HStack(spacing: Spacing.space2) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: IconSize.medium, weight: .medium))
                        .foregroundStyle(Color.ds.secondary)

                    TextField("Search...", text: $text)
                        .typography(.body, color: .ds.textPrimary)
                        .focused($isFocused)

                    if !text.isEmpty {
                        Button {
                            text = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.ds.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded = false
                            text = ""
                        }
                    } label: {
                        Text("Cancel")
                            .typography(.callout, color: .ds.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.space3)
                .frame(height: ComponentSize.inputHeight)
                .background(Color.ds.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity
                ))
            } else {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFocused = true
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: IconSize.medium, weight: .medium))
                        .foregroundStyle(Color.ds.secondary)
                        .frame(width: ComponentSize.minTapTarget, height: ComponentSize.minTapTarget)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .onChange(of: isFocused) { _, newValue in
            if !newValue && text.isEmpty {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Search Bars") {
    VStack(spacing: 24) {
        Text("Always Visible")
            .typography(.headline)

        LibrarySearchBar(text: .constant(""))

        LibrarySearchBar(text: .constant("Nature"))

        Divider()

        Text("Expandable")
            .typography(.headline)

        HStack {
            Spacer()
            ExpandableSearchBar(text: .constant(""))
        }
    }
    .padding()
    .background(Color.ds.background)
}
