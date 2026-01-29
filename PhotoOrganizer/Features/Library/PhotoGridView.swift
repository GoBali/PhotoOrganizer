//
//  PhotoGridView.swift
//  PhotoOrganizer
//
//  Photo grid display with masonry layout
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Pinch Gesture Handler (iOS)

#if os(iOS)
/// UIKit 기반 핀치 제스처 핸들러
/// SwiftUI의 MagnificationGesture가 ScrollView에서 작동하지 않는 문제를 해결
/// UIGestureRecognizerDelegate를 통해 스크롤과 핀치 제스처 동시 인식 허용
struct PinchGestureHandler: UIViewRepresentable {
    var onChanged: (CGFloat) -> Void
    var onEnded: (CGFloat) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = PassthroughView()
        view.backgroundColor = .clear
        // 이 UIView 자체는 터치를 받지 않고(스크롤/탭 방해 방지),
        // 슈퍼뷰(컨테이너)에 핀치 제스처를 부착해 ScrollView 터치와 함께 인식되게 한다.
        view.isUserInteractionEnabled = false
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let view = uiView as? PassthroughView {
            view.coordinator = context.coordinator
        }
        context.coordinator.attachPinchRecognizerIfNeeded(from: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onChanged: onChanged, onEnded: onEnded)
    }

	    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onChanged: (CGFloat) -> Void
        var onEnded: (CGFloat) -> Void
        private weak var pinchRecognizer: UIPinchGestureRecognizer?
        private weak var attachedView: UIView?
        private var minScaleDuringGesture: CGFloat = 1.0
        private var maxScaleDuringGesture: CGFloat = 1.0

        init(onChanged: @escaping (CGFloat) -> Void, onEnded: @escaping (CGFloat) -> Void) {
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

	        func attachPinchRecognizerIfNeeded(to view: UIView) {
	            if attachedView === view, pinchRecognizer != nil {
	                return
	            }

	            if let pinchRecognizer, let attachedView {
	                attachedView.removeGestureRecognizer(pinchRecognizer)
	            }

	            let pinch = UIPinchGestureRecognizer(
	                target: self,
	                action: #selector(handlePinch(_:))
	            )
	            pinch.delegate = self              // 델리게이트 설정
	            pinch.cancelsTouchesInView = false // 다른 터치 이벤트 방해 안 함

	            view.isMultipleTouchEnabled = true
	            view.addGestureRecognizer(pinch)
	            attachedView = view
	            pinchRecognizer = pinch
	        }

	        func attachPinchRecognizerIfNeeded(from view: UIView) {
	            guard let window = view.window else { return }
	            attachPinchRecognizerIfNeeded(to: window)
	        }

	        func detachPinchRecognizerIfNeeded() {
	            guard let pinchRecognizer, let attachedView else { return }
	            attachedView.removeGestureRecognizer(pinchRecognizer)
	            self.pinchRecognizer = nil
	            self.attachedView = nil
	        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                minScaleDuringGesture = gesture.scale
                maxScaleDuringGesture = gesture.scale
            case .changed:
                minScaleDuringGesture = min(minScaleDuringGesture, gesture.scale)
                maxScaleDuringGesture = max(maxScaleDuringGesture, gesture.scale)
                onChanged(gesture.scale)
            case .ended, .cancelled:
                // 사용자가 손을 떼는 순간 scale이 다시 1.0 근처로 돌아오는 경우가 있어,
                // 제스처 동안의 최대/최소 scale 중 더 크게 변한 값을 사용한다.
                let zoomOutDelta = maxScaleDuringGesture - 1.0
                let zoomInDelta = 1.0 - minScaleDuringGesture
                let effectiveScale = zoomOutDelta >= zoomInDelta ? maxScaleDuringGesture : minScaleDuringGesture
                onEnded(effectiveScale)
                gesture.scale = 1.0  // 리셋
                minScaleDuringGesture = 1.0
                maxScaleDuringGesture = 1.0
            default:
                break
            }
        }

        // 다른 제스처와 동시 인식 허용 (스크롤 + 핀치)
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return true
        }

	        deinit {
	            detachPinchRecognizerIfNeeded()
	        }
	    }

	    final class PassthroughView: UIView {
	        weak var coordinator: Coordinator?

	        override func willMove(toWindow newWindow: UIWindow?) {
	            super.willMove(toWindow: newWindow)
	            if newWindow == nil {
	                coordinator?.detachPinchRecognizerIfNeeded()
	            }
	        }

	        override func didMoveToWindow() {
	            super.didMoveToWindow()
	            coordinator?.attachPinchRecognizerIfNeeded(from: self)
	        }

        override func layoutSubviews() {
            super.layoutSubviews()
            coordinator?.attachPinchRecognizerIfNeeded(from: self)
        }
    }
}
#endif

// MARK: - Photo Card Button Style

struct PhotoCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            #if os(iOS)
            .brightness(configuration.isPressed ? -0.03 : 0)
            #endif
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            #if os(iOS)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticStyle.light.trigger()
                }
            }
            #endif
    }
}

// MARK: - Photo Grid View

struct PhotoGridView: View {
    let photos: [PhotoAsset]
    @EnvironmentObject private var library: PhotoLibraryStore
    @State private var currentMagnification: CGFloat = 1.0
    @State private var isPinching = false
    #if os(iOS) && targetEnvironment(simulator)
    @State private var simulatorMinScale: CGFloat = 1.0
    @State private var simulatorMaxScale: CGFloat = 1.0
    #endif

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Spacing.space2), count: library.gridColumns)
    }

    var body: some View {
        ZStack {
            #if os(iOS)
            #if !targetEnvironment(simulator)
            // iOS: UIKit 핀치 제스처 (ScrollView 뒤에 배치, 터치 통과)
            PinchGestureHandler(
                onChanged: { scale in
                    if !isPinching { isPinching = true }
                    currentMagnification = scale
                },
                onEnded: { scale in
                    handlePinchEnd(scale: scale)
                }
            )
            .allowsHitTesting(false)  // 터치 이벤트를 ScrollView로 통과시킴
            #endif
            #endif

            ScrollView {
                #if os(iOS)
                // iOS: LazyVGrid 사용 (고정 비율 카드에 적합)
                LazyVGrid(columns: gridColumns, spacing: Spacing.space2) {
                    ForEach(photos) { photo in
                        NavigationLink {
                            PhotoDetailView(photo: photo)
                                .environmentObject(library)
                        } label: {
                            PhotoGridItemView(photo: photo)
                        }
                        .buttonStyle(PhotoCardButtonStyle())
                        .disabled(isPinching)
                        .contextMenu {
                            contextMenuItems(for: photo)
                        }
                    }
                }
                .padding(.horizontal, Spacing.space2)
                .padding(.top, Spacing.space2)
                .padding(.bottom, Spacing.space7 + 56)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: library.gridColumns)
                #else
                // macOS: MasonryGrid 유지 (다양한 이미지 비율 지원)
                MasonryGrid(data: photos, columns: library.gridColumns, spacing: Spacing.space2) { photo in
                    NavigationLink {
                        PhotoDetailView(photo: photo)
                            .environmentObject(library)
                    } label: {
                        PhotoGridItemView(photo: photo)
                    }
                    .buttonStyle(PhotoCardButtonStyle())
                    .disabled(isPinching)
                    .contextMenu {
                        contextMenuItems(for: photo)
                    }
                }
                .padding(.horizontal, Spacing.space2)
                .padding(.top, Spacing.space2)
                .padding(.bottom, Spacing.space7 + 56)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: library.gridColumns)
                #endif
            }
        }
        .background(Color.ds.background)
        // 더블탭으로 열 수 순환 (1 → 2 → 3 → 4 → 1)
        // 시뮬레이터에서 핀치 제스처 대신 사용 가능
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                #if os(iOS)
                library.gridColumns = (library.gridColumns % 4) + 1
                #else
                // macOS: 2~6열 범위
                library.gridColumns = library.gridColumns >= 6 ? 2 : library.gridColumns + 1
                #endif
            }
            #if os(iOS)
            HapticStyle.light.trigger()
            #endif
        }
        #if os(iOS) && targetEnvironment(simulator)
        // iOS Simulator: SwiftUI MagnificationGesture (UIKit 핀치가 불안정/미동작하는 케이스 대비)
        .simultaneousGesture(simulatorPinchGesture)
        #elseif os(macOS)
        // macOS: SwiftUI MagnificationGesture 사용 (트랙패드에서 잘 작동)
        .simultaneousGesture(pinchGesture)
        #endif
    }

    // MARK: - Pinch Gesture Handling

    /// 핀치 종료 시 열 수 조정 로직 (iOS/macOS 공통)
    private func handlePinchEnd(scale: CGFloat) {
        #if os(iOS)
        let minColumns = 1  // iOS: 최소 1열
        let maxColumns = 4  // iOS: 최대 4열
        #if targetEnvironment(simulator)
        // 시뮬레이터(옵션 키 핀치)에서는 scale 변화폭이 작게 들어오는 경우가 있어 임계값을 낮게 잡는다.
        let zoomOutThreshold: CGFloat = 1.01
        let zoomInThreshold: CGFloat = 0.99
        #else
        let zoomOutThreshold: CGFloat = 1.3
        let zoomInThreshold: CGFloat = 0.7
        #endif
        #else
        let minColumns = 2  // macOS: 최소 2열
        let maxColumns = 6  // macOS: 최대 6열
        let zoomOutThreshold: CGFloat = 1.3
        let zoomInThreshold: CGFloat = 0.7
        #endif

        // 핀치 아웃 (벌리기) → 컬럼 감소 → 이미지 커짐
        if scale > zoomOutThreshold && library.gridColumns > minColumns {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                library.gridColumns -= 1
            }
            #if os(iOS)
            HapticStyle.light.trigger()
            #endif
        }
        // 핀치 인 (오므리기) → 컬럼 증가 → 이미지 작아짐
        else if scale < zoomInThreshold && library.gridColumns < maxColumns {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                library.gridColumns += 1
            }
            #if os(iOS)
            HapticStyle.light.trigger()
            #endif
        }
        currentMagnification = 1.0

        // 핀치 종료 후 딜레이를 두고 네비게이션 활성화
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPinching = false
        }
    }

    #if os(macOS)
    /// macOS용 SwiftUI MagnificationGesture (트랙패드에서 잘 작동)
    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                if !isPinching {
                    isPinching = true
                }
                currentMagnification = scale
            }
            .onEnded { scale in
                handlePinchEnd(scale: scale)
            }
    }
    #endif

    #if os(iOS) && targetEnvironment(simulator)
    private var simulatorPinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                if !isPinching {
                    isPinching = true
                    simulatorMinScale = scale
                    simulatorMaxScale = scale
                } else {
                    simulatorMinScale = min(simulatorMinScale, scale)
                    simulatorMaxScale = max(simulatorMaxScale, scale)
                }
                currentMagnification = scale
            }
            .onEnded { _ in
                let zoomOutDelta = simulatorMaxScale - 1.0
                let zoomInDelta = 1.0 - simulatorMinScale
                let effectiveScale = zoomOutDelta >= zoomInDelta ? simulatorMaxScale : simulatorMinScale
                simulatorMinScale = 1.0
                simulatorMaxScale = 1.0
                handlePinchEnd(scale: effectiveScale)
            }
    }
    #endif

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
            isLoading: image == nil,
            showInfo: library.gridColumns <= 2  // 1-2컬럼일 때만 정보 표시
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

// MARK: - Tag Grid View (통합)

struct TagGridView: View {
    let tags: [Tag]
    let onRemove: (Tag) -> Void

    // 추가 기능 (옵션)
    var enableAdd: Bool = false
    @Binding var isAddingTag: Bool
    @Binding var newTagText: String
    var onAddTag: (() -> Void)?

    @FocusState private var isInputFocused: Bool

    init(
        tags: [Tag],
        onRemove: @escaping (Tag) -> Void
    ) {
        self.tags = tags
        self.onRemove = onRemove
        self.enableAdd = false
        self._isAddingTag = .constant(false)
        self._newTagText = .constant("")
        self.onAddTag = nil
    }

    init(
        tags: [Tag],
        onRemove: @escaping (Tag) -> Void,
        isAddingTag: Binding<Bool>,
        newTagText: Binding<String>,
        onAddTag: @escaping () -> Void
    ) {
        self.tags = tags
        self.onRemove = onRemove
        self.enableAdd = true
        self._isAddingTag = isAddingTag
        self._newTagText = newTagText
        self.onAddTag = onAddTag
    }

    var body: some View {
        FlowLayout(spacing: Spacing.space2) {
            ForEach(tags, id: \.objectID) { tag in
                TagChip(
                    tag.displayName,
                    showRemove: true,
                    onRemove: { onRemove(tag) }
                )
            }

            if enableAdd {
                if isAddingTag {
                    inlineInputField
                } else {
                    addButton
                }
            }
        }
    }

    // MARK: - Add Button

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

    // MARK: - Inline Input Field

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
        onAddTag?()
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
