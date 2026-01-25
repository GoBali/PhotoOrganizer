//
//  PhotoGridView.swift
//  PhotoOrganizer
//
//  Photo grid display with masonry layout
//

import SwiftUI

// MARK: - Photo Card Button Style

struct PhotoCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Photo Grid View

struct PhotoGridView: View {
    let photos: [PhotoAsset]
    @EnvironmentObject private var library: PhotoLibraryStore
    @State private var currentMagnification: CGFloat = 1.0
    @State private var isPinching = false

    var body: some View {
        ScrollView {
            MasonryGrid(data: photos, columns: library.gridColumns, spacing: Spacing.space2) { photo in
                NavigationLink {
                    PhotoDetailView(photo: photo)
                        .environmentObject(library)
                } label: {
                    PhotoGridItemView(photo: photo)
                }
                .buttonStyle(PhotoCardButtonStyle())
                .disabled(isPinching)  // 핀치 중 네비게이션 비활성화
                .contextMenu {
                    contextMenuItems(for: photo)
                }
            }
            .padding(.horizontal, Spacing.space2)
            .padding(.top, Spacing.space2)
            .padding(.bottom, Spacing.space7 + 56) // Extra space for FAB
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: library.gridColumns)
        }
        .background(Color.ds.background)
        .simultaneousGesture(pinchGesture)
    }

    // MARK: - Pinch Gesture

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                if !isPinching {
                    isPinching = true
                }
                currentMagnification = scale
            }
            .onEnded { scale in
                // 핀치 아웃 (벌리기) → 컬럼 감소 → 이미지 커짐
                if scale > 1.3 && library.gridColumns > 2 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        library.gridColumns -= 1
                    }
                    #if os(iOS)
                    HapticStyle.light.trigger()
                    #endif
                }
                // 핀치 인 (오므리기) → 컬럼 증가 → 이미지 작아짐 (최대 6열)
                else if scale < 0.7 && library.gridColumns < 6 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        library.gridColumns += 1
                    }
                    #if os(iOS)
                    HapticStyle.light.trigger()
                    #endif
                }
                currentMagnification = 1.0

                // 핀치 종료 후 약간의 딜레이를 두고 네비게이션 활성화
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPinching = false
                }
            }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuItems(for photo: PhotoAsset) -> some View {
        Button {
            Task {
                await library.reclassify(photo)
            }
        } label: {
            Label("Reclassify", systemImage: "arrow.triangle.2.circlepath")
        }

        Divider()

        Button(role: .destructive) {
            library.delete(photo)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Photo Grid Item View

struct PhotoGridItemView: View {
    @ObservedObject var photo: PhotoAsset
    @EnvironmentObject private var library: PhotoLibraryStore
    @State private var image: Image?

    private var status: PhotoCardStatus {
        switch photo.classificationStateValue {
        case .pending:
            return .pending
        case .processing:
            return .processing
        case .completed:
            return .completed(confidence: photo.classificationConfidence)
        case .failed:
            return .failed
        }
    }

    private var locationText: String? {
        // GPS 기반 위치가 있으면 도시명 표시
        if let city = photo.city?.trimmingCharacters(in: .whitespacesAndNewlines), !city.isEmpty {
            return city
        }
        // ML 예측 위치가 있으면 ✨ 접두사와 함께 표시
        if let predicted = photo.predictedLocation?.trimmingCharacters(in: .whitespacesAndNewlines), !predicted.isEmpty {
            return "✨ \(predicted)"
        }
        return nil
    }

    var body: some View {
        PhotoCard(
            image: image,
            label: photo.displayLabel,
            location: locationText,
            status: status,
            isLoading: image == nil
        )
        .task(id: photo.fileName) {
            guard !Task.isCancelled else { return }
            if let platformImage = await library.thumbnail(for: photo, size: CGSize(width: 300, height: 300)) {
                guard !Task.isCancelled else { return }  // 완료 후에도 체크
                image = Image(platformImage: platformImage)
            }
        }
    }
}

// MARK: - Masonry Grid

struct MasonryGrid<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let columns: Int
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    init(
        data: Data,
        columns: Int = 2,
        spacing: CGFloat = Spacing.space3,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { columnIndex in
                VStack(spacing: spacing) {  // LazyVStack → VStack: environment 전파 안정화
                    ForEach(items(for: columnIndex)) { item in
                        content(item)
                    }
                }
            }
        }
    }

    private func items(for columnIndex: Int) -> [Data.Element] {
        var result: [Data.Element] = []
        for (index, item) in data.enumerated() {
            if index % columns == columnIndex {
                result.append(item)
            }
        }
        return result
    }
}

// MARK: - Tag Grid View

struct TagGridView: View {
    let tags: [Tag]
    let onRemove: (Tag) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 90), spacing: Spacing.space2)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.space2) {
            ForEach(tags, id: \.objectID) { tag in
                TagChip(
                    tag.displayName,
                    showRemove: true,
                    onRemove: { onRemove(tag) }
                )
            }
        }
    }
}

// MARK: - Tag Grid View With Add (인라인 추가 버튼 포함)

struct TagGridViewWithAdd: View {
    let tags: [Tag]
    @Binding var isAddingTag: Bool
    @Binding var newTagText: String
    let onAddTag: () -> Void
    let onRemoveTag: (Tag) -> Void

    @FocusState private var isInputFocused: Bool

    var body: some View {
        FlowLayout(spacing: Spacing.space2) {
            // 기존 태그들
            ForEach(tags, id: \.objectID) { tag in
                TagChip(
                    tag.displayName,
                    showRemove: true,
                    onRemove: { onRemoveTag(tag) }
                )
            }

            // 인라인 추가 버튼 또는 입력 필드
            if isAddingTag {
                inlineInputField
            } else {
                addButton
            }
        }
    }

    private var addButton: some View {
        Button {
            withAnimation(.easeInOut(duration: AnimationDuration.fast)) {
                isAddingTag = true
                isInputFocused = true
            }
        } label: {
            HStack(spacing: Spacing.space1) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                Text("Add")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(Color.ds.secondary)
            .padding(.horizontal, Spacing.space3)
            .padding(.vertical, Spacing.space2)
            .background(Color.ds.secondary.opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var inlineInputField: some View {
        HStack(spacing: Spacing.space1) {
            TextField("Tag name...", text: $newTagText)
                .font(.system(size: 13))
                .focused($isInputFocused)
                .frame(minWidth: 60, maxWidth: 120)
                .onSubmit {
                    submitTag()
                }

            Button {
                submitTag()
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.ds.textOnAccent)
                    .frame(width: 20, height: 20)
                    .background(Color.ds.secondary)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(newTagText.trimmingCharacters(in: .whitespaces).isEmpty)

            Button {
                cancelAdd()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.ds.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.space2)
        .padding(.vertical, Spacing.space1)
        .background(Color.ds.surfaceSecondary)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.ds.secondary, lineWidth: 1)
        )
    }

    private func submitTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onAddTag()
        newTagText = ""
        withAnimation(.easeInOut(duration: AnimationDuration.fast)) {
            isAddingTag = false
        }
    }

    private func cancelAdd() {
        newTagText = ""
        withAnimation(.easeInOut(duration: AnimationDuration.fast)) {
            isAddingTag = false
        }
    }
}

// MARK: - Flow Layout (태그 플로우 레이아웃)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let containerWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        let totalHeight = currentY + lineHeight
        let totalWidth = frames.map { $0.maxX }.max() ?? 0

        return (CGSize(width: totalWidth, height: totalHeight), frames)
    }
}
