//
//  PhotoDetailView.swift
//  PhotoOrganizer
//
//  Full-screen photo detail view with classification info and editing
//

import SwiftUI

struct PhotoDetailView: View {
    @EnvironmentObject private var library: PhotoLibraryStore
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var photo: PhotoAsset

    @State private var newTag = ""
    @State private var noteText = ""
    @State private var showDeleteConfirm = false
    @State private var image: Image?
    @State private var showFullScreenImage = false
    @State private var isFileInfoExpanded = true
    @State private var isAddingTag = false

    private var statusText: String {
        switch photo.classificationStateValue {
        case .pending:
            return "Pending"
        case .processing:
            return "Classifying"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }

    private var geocodingStatusText: String {
        switch photo.geocodingStateValue {
        case .none:
            return "No GPS"
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }

    private var geocodingStatusColor: Color {
        switch photo.geocodingStateValue {
        case .none:
            return Color.ds.textTertiary
        case .pending:
            return Color.ds.warning
        case .processing:
            return Color.ds.secondary
        case .completed:
            return Color.ds.success
        case .failed:
            return Color.ds.error
        }
    }

    // MARK: - Location Prediction Status

    private var predictionStatusText: String {
        switch photo.locationPredictionStateValue {
        case .none:
            return "GPS Available"
        case .pending:
            return "Pending"
        case .processing:
            return "Predicting..."
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }

    private var predictionStatusColor: Color {
        switch photo.locationPredictionStateValue {
        case .none:
            return Color.ds.textTertiary
        case .pending:
            return Color.ds.warning
        case .processing:
            return Color.ds.secondary
        case .completed:
            return Color.ds.info
        case .failed:
            return Color.ds.error
        }
    }

    private var statusColor: Color {
        switch photo.classificationStateValue {
        case .pending:
            return Color.ds.warning
        case .processing:
            return Color.ds.secondary
        case .completed:
            return Color.ds.success
        case .failed:
            return Color.ds.error
        }
    }

    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarTrailing
        #else
        return .automatic
        #endif
    }

    var body: some View {
        ZStack {
            // Background
            Color.ds.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Photo Display (max width for larger screens)
                    photoSection
                        .frame(maxWidth: 600)
                        .frame(maxWidth: .infinity)

                    // Info Panel (narrower for readability)
                    infoSection
                        .frame(maxWidth: 500)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, Spacing.space3)
                        .padding(.vertical, Spacing.space4)
                }
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: toolbarPlacement) {
                HStack(spacing: Spacing.space2) {
                    // Location refresh button (only if GPS data exists)
                    if photo.hasValidGPS {
                        Button {
                            Task { await library.refreshLocation(photo) }
                        } label: {
                            Image(systemName: "location.circle")
                                .font(.body)
                        }
                    }

                    // Location prediction button (only if no GPS data)
                    if !photo.hasGPSData {
                        Button {
                            Task { await library.repredictLocation(photo) }
                        } label: {
                            Image(systemName: "sparkles")
                                .font(.body)
                                .foregroundStyle(Color.ds.info)
                        }
                    }

                    Button {
                        Task { await library.reclassify(photo) }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.body)
                    }

                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundStyle(Color.ds.error)
                    }
                }
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
                library.delete(photo)
                dismiss()
            }
        }
        .task(id: photo.fileName) {
            guard !Task.isCancelled else { return }
            if let platformImage = await library.image(for: photo) {
                guard !Task.isCancelled else { return }  // 완료 후에도 체크
                image = Image(platformImage: platformImage)
            }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                if let image {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.ds.surfaceSecondary)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showFullScreenImage = true
                        }
                } else {
                    Rectangle()
                        .fill(Color.ds.surfaceSecondary)
                        .overlay {
                            ProgressView()
                                .tint(Color.ds.textTertiary)
                        }
                }

                // 확대 버튼 (이미지 로드 완료 시에만 표시)
                if image != nil {
                    Button {
                        showFullScreenImage = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white)
                            .padding(Spacing.space2)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(Spacing.space3)
                }
            }
        }
        .frame(height: screenHeight * 0.35)
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

    private var screenHeight: CGFloat {
        #if os(iOS)
        return UIScreen.main.bounds.height
        #else
        return NSScreen.main?.frame.height ?? 800
        #endif
    }

    @ViewBuilder
    private var fullScreenImageView: some View {
        if let image {
            ZStack(alignment: .topTrailing) {
                ZoomableImageView(image: image)
                    .ignoresSafeArea()

                Button {
                    showFullScreenImage = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .padding(Spacing.space3)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(Spacing.space4)
            }
            .background(Color.black)
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(spacing: Spacing.space4) {
            // Classification Hero Card (주요 정보 강조)
            ClassificationHeroCard(
                label: photo.displayLabel,
                confidence: photo.classificationConfidence,
                status: photo.classificationStateValue,
                isProcessing: photo.classificationStateValue == .processing
            ) {
                Task { await library.reclassify(photo) }
            }

            // Location Section (간결한 인라인 스타일)
            locationSection

            // Tags Section
            SectionCard(title: "Tags") {
                TagGridViewWithAdd(
                    tags: photo.tagsArray,
                    isAddingTag: $isAddingTag,
                    newTagText: $newTag,
                    onAddTag: { addTag() },
                    onRemoveTag: { tag in
                        library.removeTag(tag, from: photo)
                    }
                )
            }

            // Notes Section
            SectionCard(title: "Notes") {
                VStack(alignment: .leading, spacing: Spacing.space2) {
                    InputField(
                        "Add a note...",
                        text: $noteText,
                        isMultiline: true
                    )

                    // 저장 상태 표시
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
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .animation(.easeInOut(duration: AnimationDuration.fast), value: library.saveState)
            }

            // File Info (DisclosureGroup으로 접힘 가능)
            fileInfoSection
        }
    }

    // MARK: - Location Section

    @ViewBuilder
    private var locationSection: some View {
        if photo.hasValidGPS {
            // GPS 기반 위치 정보
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
                            .typography(.body, color: .ds.textSecondary)
                    }
                }

                Spacer()

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(geocodingStatusColor)
                        .frame(width: 6, height: 6)
                    Text(geocodingStatusText)
                        .typography(.caption1, color: .ds.textTertiary)
                }
            }
            .padding(Spacing.space3)
            .background(Color.ds.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(Color.ds.border, lineWidth: 1)
            )
        } else if let predicted = photo.predictedLocation, !predicted.isEmpty {
            // ML 예측 위치 정보
            HStack(spacing: Spacing.space3) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.ds.info)
                    .frame(width: 32, height: 32)
                    .background(Color.ds.info.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(predicted)
                        .typography(.headline, color: .ds.textPrimary)
                    HStack(spacing: 4) {
                        Text("Predicted")
                            .typography(.caption1, color: .ds.textSecondary)
                        ConfidenceBadge(
                            confidence: photo.predictedLocationConfidence,
                            size: .small
                        )
                    }
                }

                Spacer()
            }
            .padding(Spacing.space3)
            .background(Color.ds.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(Color.ds.border, lineWidth: 1)
            )
        }
    }

    // MARK: - File Info Section

    private var fileInfoSection: some View {
        DisclosureGroup(isExpanded: $isFileInfoExpanded) {
            VStack(alignment: .leading, spacing: Spacing.space3) {
                if let originalName = photo.originalFilename {
                    HStack {
                        Text("Original Name")
                            .typography(.body, color: .ds.textSecondary)
                        Spacer()
                        Text(originalName)
                            .typography(.caption1, color: .ds.textPrimary)
                            .lineLimit(1)
                    }
                }

                if let createdAt = photo.createdAt {
                    HStack {
                        Text("Added")
                            .typography(.body, color: .ds.textSecondary)
                        Spacer()
                        Text(createdAt, style: .date)
                            .typography(.body, color: .ds.textPrimary)
                    }
                }

                if photo.hasValidGPS, let coords = photo.coordinatesString {
                    HStack {
                        Text("Coordinates")
                            .typography(.body, color: .ds.textSecondary)
                        Spacer()
                        Text(coords)
                            .typography(.caption1, color: .ds.textTertiary)
                    }
                }

                // Classification details
                if photo.classificationStateValue == .failed,
                   let errorMessage = photo.classificationError {
                    HStack(alignment: .top) {
                        Text("Classification Error")
                            .typography(.body, color: .ds.textSecondary)
                        Spacer()
                        Text(errorMessage)
                            .typography(.caption1, color: .ds.error)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .padding(.top, Spacing.space2)
        } label: {
            HStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.ds.textSecondary)
                Text("File Info")
                    .typography(.callout, color: .ds.textSecondary)
            }
        }
        .tint(Color.ds.textSecondary)
        .padding(Spacing.space3)
        .background(Color.ds.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(Color.ds.border, lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        library.addTag(trimmed, to: photo)
        newTag = ""
    }
}
