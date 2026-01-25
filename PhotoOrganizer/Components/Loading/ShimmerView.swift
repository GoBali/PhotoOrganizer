//
//  ShimmerView.swift
//  PhotoOrganizer
//
//  Shimmer loading placeholder component
//

import SwiftUI

// MARK: - Shimmer View

struct ShimmerView: View {
    @State private var isAnimating = false

    let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = CornerRadius.medium) {
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        GeometryReader { geometry in
            let gradient = LinearGradient(
                colors: [
                    Color.ds.surfaceSecondary,
                    Color.ds.surface,
                    Color.ds.surfaceSecondary
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            gradient
                .mask(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
                .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                .animation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
        }
        .background(Color.ds.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Shimmer Card

struct ShimmerCard: View {
    let aspectRatio: CGFloat

    init(aspectRatio: CGFloat = 1.0) {
        self.aspectRatio = aspectRatio
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.space2) {
            ShimmerView(cornerRadius: CornerRadius.large)
                .aspectRatio(aspectRatio, contentMode: .fit)

            VStack(alignment: .leading, spacing: Spacing.space1) {
                ShimmerView(cornerRadius: CornerRadius.small)
                    .frame(height: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ShimmerView(cornerRadius: CornerRadius.small)
                    .frame(height: 12)
                    .frame(width: 80)
            }
            .padding(.horizontal, Spacing.space2)
            .padding(.bottom, Spacing.space2)
        }
        .background(Color.ds.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
    }
}

// MARK: - Shimmer Grid

struct ShimmerGrid: View {
    let columns: Int
    let itemCount: Int

    init(columns: Int = 2, itemCount: Int = 6) {
        self.columns = columns
        self.itemCount = itemCount
    }

    var body: some View {
        let gridColumns = Array(repeating: GridItem(.flexible(), spacing: Spacing.space3), count: columns)

        LazyVGrid(columns: gridColumns, spacing: Spacing.space3) {
            ForEach(0..<itemCount, id: \.self) { index in
                ShimmerCard(aspectRatio: index % 2 == 0 ? 1.0 : 0.8)
            }
        }
        .padding(.horizontal, Spacing.space4)
    }
}

// MARK: - Shimmer Line

struct ShimmerLine: View {
    let width: CGFloat?
    let height: CGFloat

    init(width: CGFloat? = nil, height: CGFloat = 16) {
        self.width = width
        self.height = height
    }

    var body: some View {
        ShimmerView(cornerRadius: CornerRadius.small)
            .frame(width: width, height: height)
    }
}

// MARK: - Shimmer Circle

struct ShimmerCircle: View {
    let size: CGFloat

    init(size: CGFloat = 40) {
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(Color.ds.surfaceSecondary)
            .frame(width: size, height: size)
            .overlay {
                ShimmerView(cornerRadius: size / 2)
            }
            .clipShape(Circle())
    }
}

// MARK: - Preview

#Preview("Shimmer Components") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Shimmer View")
                .typography(.headline)

            ShimmerView()
                .frame(height: 100)
                .padding(.horizontal)

            Text("Shimmer Card")
                .typography(.headline)

            HStack(spacing: 12) {
                ShimmerCard(aspectRatio: 1.0)
                ShimmerCard(aspectRatio: 0.8)
            }
            .padding(.horizontal)

            Text("Shimmer Lines")
                .typography(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ShimmerLine(height: 20)
                ShimmerLine(width: 200, height: 14)
                ShimmerLine(width: 150, height: 14)
            }
            .padding(.horizontal)

            Text("Shimmer Grid")
                .typography(.headline)

            ShimmerGrid(columns: 2, itemCount: 4)
        }
        .padding(.vertical)
    }
    .background(Color.ds.background)
}
