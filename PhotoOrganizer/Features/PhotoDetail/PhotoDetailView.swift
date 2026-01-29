//
//  PhotoDetailView.swift
//  PhotoOrganizer
//
//  Full-screen photo detail view with Liquid Glass Bottom Sheet
//  Features Hero Zoom transition, Swipe navigation, and Parallax scroll
//

import SwiftUI

// MARK: - Bottom Sheet State (Cross-Platform)

/// Bottom sheet states - available on all platforms
enum BottomSheetState: CaseIterable {
    case collapsed  // 최소 상태 - 핸들 정보만
    case half       // 중간 상태 - 주요 정보
    case expanded   // 확장 상태 - 모든 정보

    var heightRatio: CGFloat {
        switch self {
        case .collapsed: return 0.18
        case .half: return 0.45
        case .expanded: return 0.85
        }
    }
}

// MARK: - Action Feedback State

/// 버튼 작업 완료 피드백 상태
enum ActionFeedbackState: Equatable {
    case idle           // 기본 상태
    case processing     // 처리 중
    case success(changed: Bool)  // 성공 (변경 여부)
    case failed         // 실패
}

// MARK: - Photo Detail View

struct PhotoDetailView: View {
    @EnvironmentObject private var library: PhotoLibraryStore
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var photo: PhotoAsset

    // UI State
    @State private var newTag = ""
    @State private var noteText = ""
    @State private var showDeleteConfirm = false
    @State private var image: Image?
    @State private var platformImage: PlatformImage?
    @State private var showFullScreenImage = false
    @State private var isTagInputFocused = false
    @State private var filteredTags: [String] = []
    @State private var showAutoComplete = false

    // Bottom Sheet State
    @State private var sheetState: BottomSheetState = .half

    // Parallax State
    @State private var parallaxOffset: CGFloat = 0

    // Swipe Navigation State
    @State private var swipeOffset: CGFloat = 0
    @State private var isDraggingImage = false

    // Action Feedback State
    @State private var reclassifyFeedback: ActionFeedbackState = .idle
    @State private var locationFeedback: ActionFeedbackState = .idle

    // MARK: - Computed Properties

    private var dominantColor: Color {
        // 이미지 기반 동적 색상 (추후 구현 가능)
        Color.ds.secondary.opacity(0.3)
    }

    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarTrailing
        #else
        return .automatic
        #endif
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic Background
                backgroundGradient
                    .ignoresSafeArea()

                // Image Area (with parallax)
                VStack(spacing: 0) {
                    imageSection(geometry: geometry)
                    Spacer()
                }

                // Liquid Glass Bottom Sheet
                #if os(iOS)
                LiquidGlassBottomSheet(state: $sheetState) { currentState in
                    sheetContent(state: currentState)
                }
                #else
                // macOS: Side panel instead of bottom sheet
                HStack(spacing: 0) {
                    Spacer()
                    macOSSidePanel
                }
                #endif
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: toolbarPlacement) {
                toolbarContent
            }
        }
        .onAppear {
            noteText = photo.note ?? ""
        }
        .onChange(of: noteText) { _, newValue in
            library.updateNote(newValue, for: photo)
        }
        .confirmationDialog("Delete this photo?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                #if os(iOS)
                HapticStyle.warning.trigger()
                #endif
                library.delete(photo)
                dismiss()
            }
        }
        .task(id: photo.fileName) {
            guard !Task.isCancelled else { return }
            if let loadedImage = await library.image(for: photo) {
                guard !Task.isCancelled else { return }
                platformImage = loadedImage
                image = Image(platformImage: loadedImage)
            }
        }
    }

    // MARK: - Background Gradient

    private var backgroundGradient: some View {
        ZStack {
            Color.ds.background

            // Radial gradient from dominant color
            RadialGradient(
                colors: [
                    dominantColor.opacity(0.4),
                    dominantColor.opacity(0.1),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 500
            )
        }
    }

    // MARK: - Image Section

    private func imageSection(geometry: GeometryProxy) -> some View {
        let imageHeight = geometry.size.height * 0.55 // 이미지가 더 크게

        return ZStack(alignment: .topTrailing) {
            if let image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: imageHeight)
                    // Parallax effect
                    .offset(y: -parallaxOffset * 0.3)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        #if os(iOS)
                        HapticStyle.light.trigger()
                        #endif
                        showFullScreenImage = true
                    }
                    // Swipe gesture for navigation
                    .gesture(swipeGesture)
            } else {
                Rectangle()
                    .fill(Color.ds.surfaceSecondary)
                    .frame(height: imageHeight)
                    .overlay {
                        ProgressView()
                            .tint(Color.ds.textTertiary)
                    }
            }

        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showFullScreenImage) {
            fullScreenImageView
        }
        #else
        .sheet(isPresented: $showFullScreenImage) {
            fullScreenImageView
                .frame(minWidth: 600, minHeight: 500)
        }
        #endif
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onChanged { value in
                if abs(value.translation.width) > abs(value.translation.height) {
                    isDraggingImage = true
                    swipeOffset = value.translation.width
                }
            }
            .onEnded { value in
                isDraggingImage = false

                let threshold: CGFloat = 100
                if value.translation.width > threshold {
                    // Swipe right - previous photo
                    navigateToPreviousPhoto()
                } else if value.translation.width < -threshold {
                    // Swipe left - next photo
                    navigateToNextPhoto()
                }

                withAnimation(Motion.spring()) {
                    swipeOffset = 0
                }
            }
    }

    private func navigateToPreviousPhoto() {
        #if os(iOS)
        HapticStyle.light.trigger()
        #endif
        // 이전 사진으로 이동하는 로직 (추후 구현)
    }

    private func navigateToNextPhoto() {
        #if os(iOS)
        HapticStyle.light.trigger()
        #endif
        // 다음 사진으로 이동하는 로직 (추후 구현)
    }

    // MARK: - Full Screen Image View

    @ViewBuilder
    private var fullScreenImageView: some View {
        if let platformImage {
            ZStack(alignment: .topTrailing) {
                ZoomableImageView(platformImage: platformImage)
                    .ignoresSafeArea()

                Button {
                    showFullScreenImage = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(Spacing.space3)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(Spacing.space4)
            }
            .background(Color.black)
        }
    }

    // MARK: - Sheet Content

    @ViewBuilder
    private func sheetContent(state: BottomSheetState) -> some View {
        VStack(alignment: .leading, spacing: Spacing.space4) {
            // AI Classification Card (항상 표시)
            AIClassificationCard(
                label: photo.displayLabel,
                confidence: photo.classificationConfidence,
                status: photo.classificationStateValue,
                isPredictedLocation: !photo.hasGPSData && photo.predictedLocation != nil,
                predictedLocation: photo.predictedLocation,
                locationConfidence: photo.predictedLocationConfidence,
                feedbackState: reclassifyFeedback
            ) {
                Task { await performReclassify() }
            }

            // Location Section (중간 + 확장 상태)
            if state != .collapsed {
                locationSection
            }

            // Tags Section (중간 + 확장 상태)
            if state != .collapsed {
                tagsSection
            }

            // Notes Section (확장 상태만)
            if state == .expanded {
                notesSection
            }
        }
        .animation(Motion.smooth(), value: state)
    }

    // MARK: - Location Section

    @ViewBuilder
    private var locationSection: some View {
        if photo.hasValidGPS {
            glassCard {
                HStack(spacing: Spacing.space3) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.ds.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color.ds.secondary.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        if let city = photo.city, !city.isEmpty {
                            Text(city)
                                .typography(.headline, color: .ds.textPrimary)
                        }
                        if let country = photo.country, !country.isEmpty {
                            Text(country)
                                .typography(.subheadline, color: .ds.textSecondary)
                        }

                        // 피드백 캡션
                        if case .success(let changed) = locationFeedback {
                            Text(changed ? "Updated" : "No changes")
                                .typography(.caption2, color: changed ? .ds.success : .ds.textTertiary)
                                .transition(.opacity.combined(with: .scale))
                        }
                    }

                    Spacer()

                    // Refresh button with feedback
                    LocationRefreshButton(
                        feedbackState: locationFeedback,
                        action: { Task { await performLocationRefresh() } }
                    )
                }
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        glassCard {
            VStack(alignment: .leading, spacing: Spacing.space3) {
                // Header
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.ds.textSecondary)
                    Text("Tags")
                        .typography(.subheadline, color: .ds.textSecondary)
                    Spacer()
                }

                // 현재 태그 목록
                if !photo.tagsArray.isEmpty {
                    FlowLayout(spacing: Spacing.space2) {
                        ForEach(photo.tagsArray, id: \.self) { tag in
                            TagChipView(tag: tag.name ?? "") {
                                #if os(iOS)
                                HapticStyle.soft.trigger()
                                #endif
                                library.removeTag(tag, from: photo)
                            }
                        }
                    }
                }

                // 인라인 태그 입력 필드 (항상 표시)
                VStack(alignment: .leading, spacing: Spacing.space2) {
                    HStack(spacing: Spacing.space2) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.ds.textTertiary)

                        TextField("Add tag...", text: $newTag)
                            .textFieldStyle(.plain)
                            .typography(.subheadline, color: .ds.textPrimary)
                            .onSubmit {
                                addTag()
                            }
                            .onChange(of: newTag) { _, newValue in
                                updateAutoComplete(query: newValue)
                            }

                        if !newTag.isEmpty {
                            Button {
                                addTag()
                            } label: {
                                Image(systemName: "return")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.ds.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.space3)
                    .padding(.vertical, Spacing.space2)
                    .background(Color.ds.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))

                    // 자동완성 드롭다운
                    if showAutoComplete && !filteredTags.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(filteredTags, id: \.self) { suggestion in
                                Button {
                                    selectAutoCompleteSuggestion(suggestion)
                                } label: {
                                    HStack {
                                        Text(suggestion)
                                            .typography(.subheadline, color: .ds.textPrimary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, Spacing.space3)
                                    .padding(.vertical, Spacing.space2)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if suggestion != filteredTags.last {
                                    Divider()
                                        .background(Color.ds.border)
                                }
                            }
                        }
                        .background(Color.ds.surface)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .stroke(Color.ds.border, lineWidth: 0.5)
                        )
                    }
                }

                // 추천 태그 (기존에 사용된 태그)
                let suggestions = library.suggestedTags(for: photo, limit: 6)
                if !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.space2) {
                        Text("Suggestions")
                            .typography(.caption2, color: .ds.textTertiary)

                        FlowLayout(spacing: Spacing.space2) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                SuggestionChipView(tag: suggestion) {
                                    #if os(iOS)
                                    HapticStyle.soft.trigger()
                                    #endif
                                    library.addTag(suggestion, to: photo)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Tag AutoComplete

    private func updateAutoComplete(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            filteredTags = []
            showAutoComplete = false
        } else {
            filteredTags = library.filterTags(matching: trimmed, excluding: photo)
            showAutoComplete = !filteredTags.isEmpty
        }
    }

    private func selectAutoCompleteSuggestion(_ suggestion: String) {
        #if os(iOS)
        HapticStyle.soft.trigger()
        #endif
        library.addTag(suggestion, to: photo)
        newTag = ""
        showAutoComplete = false
        filteredTags = []
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        glassCard {
            VStack(alignment: .leading, spacing: Spacing.space3) {
                HStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.ds.textSecondary)
                    Text("Notes")
                        .typography(.subheadline, color: .ds.textSecondary)
                }

                TextEditor(text: $noteText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
                    .padding(Spacing.space2)
                    .background(Color.ds.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    .overlay(
                        Group {
                            if noteText.isEmpty {
                                Text("Add a note...")
                                    .typography(.body, color: .ds.textTertiary)
                                    .padding(Spacing.space3)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )

                // Save indicator
                if library.saveState != .idle {
                    HStack(spacing: Spacing.space1) {
                        if library.saveState == .saving {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else if library.saveState == .saved {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.ds.success)
                        }
                        Text(library.saveState.text)
                            .typography(.caption1, color: .ds.textTertiary)
                    }
                }
            }
        }
    }


    // MARK: - Glass Card Helper

    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(Spacing.space3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    #if os(iOS)
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .fill(.ultraThinMaterial)
                    #else
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .fill(Color.ds.surface)
                    #endif

                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .fill(Color.ds.glassBackground.opacity(0.3))

                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .stroke(Color.ds.glassBorder, lineWidth: 0.5)
                }
            )
    }

    // MARK: - Toolbar Content

    private var toolbarContent: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            Image(systemName: "trash")
                .font(.body)
                .foregroundStyle(Color.ds.error)
        }
    }

    // MARK: - macOS Side Panel

    #if os(macOS)
    private var macOSSidePanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.space4) {
                AIClassificationCard(
                    label: photo.displayLabel,
                    confidence: photo.classificationConfidence,
                    status: photo.classificationStateValue,
                    isPredictedLocation: !photo.hasGPSData && photo.predictedLocation != nil,
                    predictedLocation: photo.predictedLocation,
                    locationConfidence: photo.predictedLocationConfidence,
                    feedbackState: reclassifyFeedback
                ) {
                    Task { await performReclassify() }
                }

                locationSection
                tagsSection
                notesSection
            }
            .padding(Spacing.space4)
        }
        .frame(width: 320)
        .background(Color.ds.surface)
    }
    #endif

    // MARK: - Actions

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        #if os(iOS)
        HapticStyle.success.trigger()
        #endif
        library.addTag(trimmed, to: photo)
        newTag = ""
        showAutoComplete = false
        filteredTags = []
    }

    // MARK: - Reclassify Action

    private func performReclassify() async {
        withAnimation(Motion.smooth()) {
            reclassifyFeedback = .processing
        }

        let result = await library.reclassify(photo)

        withAnimation(Motion.smooth()) {
            if result.success {
                reclassifyFeedback = .success(changed: result.changed)
                #if os(iOS)
                HapticStyle.success.trigger()
                #endif
            } else {
                reclassifyFeedback = .failed
                #if os(iOS)
                HapticStyle.error.trigger()
                #endif
            }
        }

        // 2초 후 자동 리셋
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        withAnimation(Motion.smooth()) {
            reclassifyFeedback = .idle
        }
    }

    // MARK: - Location Refresh Action

    private func performLocationRefresh() async {
        withAnimation(Motion.smooth()) {
            locationFeedback = .processing
        }

        let result = await library.refreshLocation(photo)

        withAnimation(Motion.smooth()) {
            if result.success {
                locationFeedback = .success(changed: result.changed)
                #if os(iOS)
                if result.changed {
                    HapticStyle.success.trigger()
                } else {
                    HapticStyle.soft.trigger()
                }
                #endif
            } else {
                locationFeedback = .failed
                #if os(iOS)
                HapticStyle.error.trigger()
                #endif
            }
        }

        // 2초 후 자동 리셋
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        withAnimation(Motion.smooth()) {
            locationFeedback = .idle
        }
    }
}

// MARK: - Tag Chip View

private struct TagChipView: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Spacing.space1) {
            Text(tag)
                .typography(.caption1, color: .ds.textPrimary)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.ds.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.space2)
        .padding(.vertical, Spacing.space1)
        .background(Color.ds.surfaceSecondary)
        .clipShape(Capsule())
    }
}

// MARK: - Suggestion Chip View (추천 태그용)

private struct SuggestionChipView: View {
    let tag: String
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: Spacing.space1) {
                Image(systemName: "plus")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.ds.secondary)

                Text(tag)
                    .typography(.caption1, color: .ds.textSecondary)
            }
            .padding(.horizontal, Spacing.space2)
            .padding(.vertical, Spacing.space1)
            .background(Color.ds.secondary.opacity(0.1))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.ds.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Liquid Glass Bottom Sheet (iOS only)

#if os(iOS)
struct LiquidGlassBottomSheet<Content: View>: View {
    @Binding var state: BottomSheetState
    @ViewBuilder let content: (BottomSheetState) -> Content

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    private let minHeight: CGFloat = 120
    private let grabHandleHeight: CGFloat = 20

    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let currentHeight = height(for: state, screenHeight: screenHeight)

            VStack(spacing: 0) {
                // Grab Handle
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.ds.textTertiary.opacity(0.5))
                        .frame(width: 36, height: 5)
                        .padding(.top, Spacing.space2)
                        .padding(.bottom, Spacing.space3)
                }
                .frame(height: grabHandleHeight)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())

                // Content
                ScrollView {
                    content(state)
                        .padding(.horizontal, Spacing.space4)
                        .padding(.bottom, Spacing.space6)
                }
                .scrollDisabled(state == .collapsed)
            }
            .frame(height: max(minHeight, currentHeight - dragOffset))
            .frame(maxWidth: .infinity)
            .background(glassBackground)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: CornerRadius.xxl,
                    topTrailingRadius: CornerRadius.xxl
                )
            )
            .overlay(alignment: .top) {
                UnevenRoundedRectangle(
                    topLeadingRadius: CornerRadius.xxl,
                    topTrailingRadius: CornerRadius.xxl
                )
                .stroke(
                    LinearGradient(
                        colors: [Color.ds.glassHighlight, Color.ds.glassBorder],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            }
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -10)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
            .offset(y: screenHeight - max(minHeight, currentHeight - dragOffset))
            .gesture(dragGesture(screenHeight: screenHeight))
            .animation(isDragging ? nil : Motion.sheetSnap(), value: state)
            .animation(isDragging ? nil : Motion.sheetSnap(), value: dragOffset)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var glassBackground: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            LinearGradient(
                colors: [Color.ds.glassBackground, Color.ds.glassBackground.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func height(for state: BottomSheetState, screenHeight: CGFloat) -> CGFloat {
        max(minHeight, screenHeight * state.heightRatio)
    }

    private func dragGesture(screenHeight: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation.height
            }
            .onEnded { value in
                isDragging = false
                let velocity = value.predictedEndTranslation.height - value.translation.height
                let currentHeight = height(for: state, screenHeight: screenHeight) - dragOffset
                let targetState = calculateTargetState(currentHeight: currentHeight, velocity: velocity, screenHeight: screenHeight)
                dragOffset = 0
                state = targetState
                HapticStyle.medium.trigger()
            }
    }

    private func calculateTargetState(currentHeight: CGFloat, velocity: CGFloat, screenHeight: CGFloat) -> BottomSheetState {
        let collapsedHeight = height(for: .collapsed, screenHeight: screenHeight)
        let halfHeight = height(for: .half, screenHeight: screenHeight)
        let expandedHeight = height(for: .expanded, screenHeight: screenHeight)

        if velocity < -500 {
            switch state {
            case .collapsed: return .half
            case .half: return .expanded
            case .expanded: return .expanded
            }
        } else if velocity > 500 {
            switch state {
            case .collapsed: return .collapsed
            case .half: return .collapsed
            case .expanded: return .half
            }
        }

        let distances = [
            (BottomSheetState.collapsed, abs(currentHeight - collapsedHeight)),
            (BottomSheetState.half, abs(currentHeight - halfHeight)),
            (BottomSheetState.expanded, abs(currentHeight - expandedHeight))
        ]
        return distances.min(by: { $0.1 < $1.1 })?.0 ?? state
    }
}
#endif

// MARK: - AI Classification Card

struct AIClassificationCard: View {
    let label: String
    let confidence: Double
    let status: ClassificationState
    let isPredictedLocation: Bool
    let predictedLocation: String?
    let locationConfidence: Double
    let feedbackState: ActionFeedbackState
    var onReclassify: (() -> Void)?

    @State private var animatedConfidence: Double
    @State private var rotationAngle: Double = 0

    init(
        label: String,
        confidence: Double,
        status: ClassificationState,
        isPredictedLocation: Bool = false,
        predictedLocation: String? = nil,
        locationConfidence: Double = 0,
        feedbackState: ActionFeedbackState = .idle,
        onReclassify: (() -> Void)? = nil
    ) {
        self.label = label
        self.confidence = confidence
        self.status = status
        self.isPredictedLocation = isPredictedLocation
        self.predictedLocation = predictedLocation
        self.locationConfidence = locationConfidence
        self.feedbackState = feedbackState
        self.onReclassify = onReclassify
        self._animatedConfidence = State(initialValue: confidence)
    }

    private var confidenceColor: Color {
        if confidence >= 0.8 { return Color.ds.confidenceHigh }
        else if confidence >= 0.5 { return Color.ds.confidenceMid }
        else { return Color.ds.confidenceLow }
    }

    private var confidenceText: String {
        if confidence >= 0.8 { return "High Confidence" }
        else if confidence >= 0.5 { return "Medium Confidence" }
        else { return "Low Confidence" }
    }

    private var categoryIcon: String {
        // AI를 나타내는 통일된 아이콘 사용
        return "sparkles"
    }

    // 피드백 상태 헬퍼
    private var isSuccessState: Bool {
        if case .success = feedbackState { return true }
        return false
    }

    private var successIconColor: Color {
        if case .success(let changed) = feedbackState {
            return changed ? Color.ds.success : Color.ds.textTertiary
        }
        return Color.ds.success
    }

    private var buttonBackgroundColor: Color {
        switch feedbackState {
        case .idle, .processing:
            return Color.ds.secondary.opacity(0.1)
        case .success(let changed):
            return changed ? Color.ds.success.opacity(0.15) : Color.ds.textTertiary.opacity(0.1)
        case .failed:
            return Color.ds.error.opacity(0.15)
        }
    }

    // 회전 애니메이션
    private func startRotationAnimation() {
        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }

    private func stopRotationAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            rotationAngle = 0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.space4) {
            // Header
            HStack(spacing: Spacing.space3) {
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.ds.aiGradientStart, Color.ds.aiGradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                    Image(systemName: categoryIcon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.space2) {
                        Text(label)
                            .typography(.title3, color: .ds.textPrimary)
                            .lineLimit(1)
                        // AI Badge
                        HStack(spacing: 2) {
                            Image(systemName: "sparkles").font(.system(size: 8, weight: .bold))
                            Text("AI").font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(LinearGradient(colors: [Color.ds.aiGradientStart, Color.ds.aiGradientEnd], startPoint: .leading, endPoint: .trailing))
                        .clipShape(Capsule())
                    }
                    Text(status == .processing ? "Classifying..." : "AI Classification")
                        .typography(.caption1, color: .ds.textSecondary)
                }

                Spacer()

                if let onReclassify {
                    // Reclassify 버튼 with feedback
                    VStack(spacing: 4) {
                        Button(action: onReclassify) {
                            ZStack {
                                // Idle/Processing 아이콘
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Color.ds.secondary)
                                    .rotationEffect(.degrees(rotationAngle))
                                    .opacity(feedbackState == .idle || feedbackState == .processing ? 1 : 0)
                                    .scaleEffect(feedbackState == .idle || feedbackState == .processing ? 1 : 0.5)

                                // Success 아이콘
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(successIconColor)
                                    .opacity(isSuccessState ? 1 : 0)
                                    .scaleEffect(isSuccessState ? 1 : 0.5)

                                // Failed 아이콘
                                Image(systemName: "exclamationmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.ds.error)
                                    .opacity(feedbackState == .failed ? 1 : 0)
                                    .scaleEffect(feedbackState == .failed ? 1 : 0.5)
                            }
                            .frame(width: 36, height: 36)
                            .background(buttonBackgroundColor)
                            .clipShape(Circle())
                            .animation(Motion.smooth(), value: feedbackState)
                        }
                        .buttonStyle(.plain)
                        .disabled(feedbackState == .processing || status == .processing)

                        // 피드백 캡션
                        if case .success(let changed) = feedbackState {
                            Text(changed ? "Updated" : "No changes")
                                .typography(.caption2, color: changed ? .ds.success : .ds.textTertiary)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .onChange(of: feedbackState) { _, newValue in
                        if newValue == .processing {
                            startRotationAnimation()
                        } else {
                            stopRotationAnimation()
                        }
                    }
                }
            }

            // Confidence Bar
            if status == .completed {
                VStack(alignment: .leading, spacing: Spacing.space2) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.ds.surfaceTertiary).frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(colors: [confidenceColor, confidenceColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geometry.size.width * animatedConfidence, height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text(confidenceText).typography(.caption1, color: .ds.textSecondary)
                        Spacer()
                        Text("\(Int(confidence * 100))%").typography(.caption1, color: confidenceColor).fontWeight(.semibold)
                    }
                }
            }

            // Predicted Location
            if isPredictedLocation, let location = predictedLocation, !location.isEmpty {
                Divider().background(Color.ds.border)
                HStack(spacing: Spacing.space3) {
                    Image(systemName: "sparkles").font(.system(size: 14, weight: .medium)).foregroundStyle(Color.ds.aiPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(location).typography(.subheadline, color: .ds.textPrimary)
                        HStack(spacing: Spacing.space1) {
                            Text("AI Predicted").typography(.caption2, color: .ds.textTertiary)
                            if locationConfidence > 0 {
                                Text("•").foregroundStyle(Color.ds.textTertiary)
                                Text("\(Int(locationConfidence * 100))%").typography(.caption2, color: .ds.aiPrimary)
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(Spacing.space4)
        .background(glassCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) { animatedConfidence = confidence }
        }
        .onChange(of: confidence) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) { animatedConfidence = newValue }
        }
    }

    private var glassCardBackground: some View {
        ZStack {
            #if os(iOS)
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous).fill(.ultraThinMaterial)
            #else
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous).fill(Color.ds.surface)
            #endif
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous).fill(Color.ds.glassBackground.opacity(0.5))
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous).stroke(Color.ds.glassBorder, lineWidth: 1)
        }
    }
}

// MARK: - Location Refresh Button

private struct LocationRefreshButton: View {
    let feedbackState: ActionFeedbackState
    let action: () -> Void

    @State private var rotationAngle: Double = 0

    private var isSuccessState: Bool {
        if case .success = feedbackState { return true }
        return false
    }

    private var successIconColor: Color {
        if case .success(let changed) = feedbackState {
            return changed ? Color.ds.success : Color.ds.textTertiary
        }
        return Color.ds.success
    }

    private var buttonBackgroundColor: Color {
        switch feedbackState {
        case .idle, .processing:
            return Color.clear
        case .success(let changed):
            return changed ? Color.ds.success.opacity(0.1) : Color.clear
        case .failed:
            return Color.ds.error.opacity(0.1)
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Idle/Processing 아이콘
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.ds.textSecondary)
                    .rotationEffect(.degrees(rotationAngle))
                    .opacity(feedbackState == .idle || feedbackState == .processing ? 1 : 0)
                    .scaleEffect(feedbackState == .idle || feedbackState == .processing ? 1 : 0.5)

                // Success 아이콘
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(successIconColor)
                    .opacity(isSuccessState ? 1 : 0)
                    .scaleEffect(isSuccessState ? 1 : 0.5)

                // Failed 아이콘
                Image(systemName: "exclamationmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ds.error)
                    .opacity(feedbackState == .failed ? 1 : 0)
                    .scaleEffect(feedbackState == .failed ? 1 : 0.5)
            }
            .frame(width: 28, height: 28)
            .background(buttonBackgroundColor)
            .clipShape(Circle())
            .animation(Motion.smooth(), value: feedbackState)
        }
        .buttonStyle(.plain)
        .disabled(feedbackState == .processing)
        .onChange(of: feedbackState) { _, newValue in
            if newValue == .processing {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    rotationAngle = 0
                }
            }
        }
    }
}
