//
//  LibraryView.swift
//  PhotoOrganizer
//
//  Main library view with card feed layout and filtering
//

import CoreData
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var library: PhotoLibraryStore

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PhotoAsset.createdAt, ascending: false)]
    )
    private var photos: FetchedResults<PhotoAsset>

    @State private var pickerSelection: [PhotosPickerItem] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showFileImporter = false
    @State private var isDropTargeted = false
    @State private var showReclassifyAllConfirm = false
    @State private var isReclassifyingAll = false
    @State private var reclassifyProgress: (current: Int, total: Int)?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ds.background.ignoresSafeArea()

                if filteredPhotos.isEmpty {
                    emptyStateView
                        .frame(maxHeight: .infinity)
                } else {
                    feedContent
                }
            }
            .navigationTitle("Feed")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .searchable(text: $library.searchText, prompt: "Search tags, notes, or labels")
            .toolbar { toolbarContent }
            .overlay(alignment: .bottom) { importingOverlay }
        }
        .onChange(of: pickerSelection, handlePickerChange)
        #if os(macOS)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true,
            onCompletion: handleFileImport
        )
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted, perform: handleDrop)
        #endif
        .onChange(of: library.lastError, handleError)
        .alert("Something went wrong", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .confirmationDialog(
            "Reclassify All Photos?",
            isPresented: $showReclassifyAllConfirm,
            titleVisibility: .visible
        ) {
            Button("Reclassify \(photos.count) photos") {
                Task { await reclassifyAllPhotos() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will re-analyze all \(photos.count) photos using image classification. This may take a while.")
        }
        .animation(.easeInOut(duration: AnimationDuration.normal), value: library.isImporting)
    }

    private var filteredPhotos: [PhotoAsset] {
        library.filteredPhotos(from: photos)
    }

    // MARK: - Feed Content

    private var feedContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                CategoryFilterBar(
                    categories: categoryItems,
                    selectedCategory: $library.selectedCategory
                )
                .padding(.bottom, Spacing.space3)

                if library.gridColumns == 1 {
                    feedLayout
                } else {
                    gridLayout
                }
            }
            .padding(.bottom, Spacing.space7)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: library.gridColumns)
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                #if os(iOS)
                library.gridColumns = (library.gridColumns % GridConfig.iOSMaxColumns) + 1
                #else
                library.gridColumns = library.gridColumns >= GridConfig.macOSMaxColumns ? 1 : library.gridColumns + 1
                #endif
            }
            #if os(iOS)
            HapticStyle.light.trigger()
            #endif
        }
    }

    // MARK: - 1-Column Feed Layout

    private var feedLayout: some View {
        LazyVStack(spacing: Spacing.space5) {
            ForEach(Array(filteredPhotos.enumerated()), id: \.element.id) { index, photo in
                photoNavigationLink(photo: photo, index: index) {
                    FeedCardItem(photo: photo)
                }
            }
        }
        .padding(.horizontal, Spacing.space4)
    }

    // MARK: - Multi-Column Grid Layout

    private var gridLayout: some View {
        let spacing = library.gridColumns >= 3 ? Spacing.space1 : Spacing.space2
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: library.gridColumns),
            spacing: spacing
        ) {
            ForEach(Array(filteredPhotos.enumerated()), id: \.element.id) { index, photo in
                photoNavigationLink(photo: photo, index: index) {
                    GridCardItem(photo: photo, columns: library.gridColumns)
                }
            }
        }
        .padding(.horizontal, library.gridColumns >= 3 ? Spacing.space1 : Spacing.space3)
    }

    // MARK: - Shared Navigation Link

    private func photoNavigationLink<Content: View>(
        photo: PhotoAsset,
        index: Int,
        @ViewBuilder label: () -> Content
    ) -> some View {
        NavigationLink {
            PhotoDetailView(photos: filteredPhotos, initialIndex: index)
                .environmentObject(library)
        } label: {
            label()
        }
        .buttonStyle(PhotoCardButtonStyle())
        .contextMenu {
            contextMenuItems(for: photo)
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuItems(for photo: PhotoAsset) -> some View {
        Button {
            Task { await library.reclassify(photo) }
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

    // MARK: - Category Items

    private var categoryItems: [CategoryItem] {
        var unclassifiedCount = 0
        var labelCounts: [String: Int] = [:]
        var cityCounts: [String: Int] = [:]
        var predictedCounts: [String: Int] = [:]

        for photo in photos {
            let label = photo.classificationLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
            let city = photo.city?.trimmingCharacters(in: .whitespacesAndNewlines)
            let predicted = photo.predictedLocation?.trimmingCharacters(in: .whitespacesAndNewlines)
            let hasLabel = !(label?.isEmpty ?? true)
            let hasCity = !(city?.isEmpty ?? true)
            let hasPredicted = !(predicted?.isEmpty ?? true)

            if !hasLabel && !hasCity && !hasPredicted { unclassifiedCount += 1 }
            if hasLabel, let label { labelCounts[label, default: 0] += 1 }
            if hasCity, let city { cityCounts[city, default: 0] += 1 }
            if hasPredicted, let predicted { predictedCounts[predicted, default: 0] += 1 }
        }

        var items = [
            CategoryItem(name: "All", count: photos.count),
            CategoryItem(name: "Unclassified", count: unclassifiedCount)
        ]
        items += cityCounts.keys.sorted().map { CategoryItem(name: "\u{1F4CD} \($0)", count: cityCounts[$0]!) }
        items += predictedCounts.keys.sorted().map { CategoryItem(name: "\u{2728} \($0)", count: predictedCounts[$0]!) }
        items += labelCounts.keys.sorted().map { CategoryItem(name: $0, count: labelCounts[$0]!) }
        return items
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        if !library.searchText.isEmpty {
            EmptyStateView.noResults(searchText: library.searchText)
        } else if library.selectedCategory != "All" {
            EmptyStateView.noPhotosInCategory(category: library.selectedCategory)
        } else {
            EmptyStateView.noPhotos()
        }
    }

    // MARK: - Importing Overlay

    @ViewBuilder
    private var importingOverlay: some View {
        if library.isImporting {
            ImportProgressToast(progress: library.importProgress)
                .padding(.bottom, Spacing.space6)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: Spacing.space2) {
                Button {
                    showReclassifyAllConfirm = true
                } label: {
                    if isReclassifyingAll {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
                .disabled(isReclassifyingAll || photos.isEmpty)

                PhotosPicker(selection: $pickerSelection, maxSelectionCount: 25, matching: .images) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.ds.secondary)
                }
            }
        }
        #elseif os(macOS)
        ToolbarItemGroup(placement: .automatic) {
            Button {
                showReclassifyAllConfirm = true
            } label: {
                Label("Reclassify All", systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(isReclassifyingAll || photos.isEmpty)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            PhotoImportButton(selection: $pickerSelection, maxSelectionCount: 25)
            Button {
                showFileImporter = true
            } label: {
                Label("Import Files", systemImage: "folder.badge.plus")
            }
        }
        #endif
    }

    // MARK: - Event Handlers

    private func handlePickerChange(_ oldValue: [PhotosPickerItem], _ newValue: [PhotosPickerItem]) {
        guard !newValue.isEmpty else { return }
        Task {
            await library.importPhotos(from: newValue)
            pickerSelection.removeAll()
        }
    }

    private func handleError(_ oldValue: String?, _ newValue: String?) {
        guard let newValue else { return }
        errorMessage = newValue
        showError = true
    }

    // MARK: - macOS Helpers

    #if os(macOS)
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task { await library.importFiles(from: urls) }
        case .failure:
            library.lastError = "Failed to import one or more files."
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        Task {
            let urls = await loadDroppedFileURLs(from: providers)
            guard !urls.isEmpty else { return }
            await library.importFiles(from: urls)
        }
        return true
    }

    private func loadDroppedFileURLs(from providers: [NSItemProvider]) async -> [URL] {
        var urls: [URL] = []
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            if let url = await loadFileURL(from: provider), isImageURL(url) {
                urls.append(url)
            }
        }
        return urls
    }

    private func loadFileURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url)
                } else if let url = item as? URL {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func isImageURL(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else { return false }
        return type.conforms(to: .image)
    }
    #endif

    // MARK: - Reclassify All Photos

    private func reclassifyAllPhotos() async {
        guard !photos.isEmpty else { return }
        isReclassifyingAll = true
        reclassifyProgress = (current: 0, total: photos.count)

        defer {
            isReclassifyingAll = false
            reclassifyProgress = nil
        }

        for (index, photo) in photos.enumerated() {
            reclassifyProgress = (current: index + 1, total: photos.count)
            await library.reclassify(photo)
        }
    }
}

// MARK: - Feed Card Item

struct FeedCardItem: View {
    @ObservedObject var photo: PhotoAsset
    @EnvironmentObject private var library: PhotoLibraryStore
    @State private var image: Image?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            photoImageView
            metadataSection
        }
        .elevation(.low)
        .loadThumbnail(photo: photo, library: library, image: $image, size: 600)
    }

    // MARK: - Photo Image

    private var photoImageView: some View {
        ThumbnailImageView(image: image)
            .aspectRatio(GridTokens.landscapeAspectRatio, contentMode: .fit)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: CornerRadius.large,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: CornerRadius.large
                )
            )
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.space2) {
            classificationRow
            locationRow
            tagsRow
            timestampRow
        }
        .padding(Spacing.space3)
        .background(Color.ds.surface)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: CornerRadius.large,
                bottomTrailingRadius: CornerRadius.large,
                topTrailingRadius: 0
            )
        )
    }

    private var classificationRow: some View {
        HStack {
            Text(photo.displayLabel)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.ds.textPrimary)

            Spacer()

            if photo.classificationStateValue == .completed {
                ConfidenceBadge(confidence: photo.classificationConfidence, size: .small)
            } else if photo.classificationStateValue == .processing {
                ProgressView()
                    .scaleEffect(0.6)
            }
        }
    }

    @ViewBuilder
    private var locationRow: some View {
        if let location = photo.effectiveLocation {
            LocationLabel(location: location)
        }
    }

    @ViewBuilder
    private var tagsRow: some View {
        if !photo.tagsArray.isEmpty {
            HStack(spacing: Spacing.space1 + 2) {
                ForEach(photo.tagsArray.prefix(3), id: \.objectID) { tag in
                    Text(tag.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.ds.secondary)
                        .padding(.horizontal, Spacing.space2)
                        .padding(.vertical, 3)
                        .background(Color.ds.secondary.opacity(Opacity.hover))
                        .clipShape(Capsule())
                }
                if photo.tagsArray.count > 3 {
                    Text("+\(photo.tagsArray.count - 3)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.ds.textTertiary)
                }
            }
        }
    }

    @ViewBuilder
    private var timestampRow: some View {
        if let date = photo.createdAt {
            Text(date, style: .date)
                .font(.system(size: 12))
                .foregroundStyle(Color.ds.textTertiary)
        }
    }
}

// MARK: - Grid Card Item (2+ columns)

struct GridCardItem: View {
    @ObservedObject var photo: PhotoAsset
    let columns: Int
    @EnvironmentObject private var library: PhotoLibraryStore
    @State private var image: Image?

    var body: some View {
        if columns == 2 {
            twoColumnCard
        } else {
            compactCard
        }
    }

    // MARK: - 2-Column Card

    private var twoColumnCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ThumbnailImageView(image: image)
                .aspectRatio(GridTokens.landscapeAspectRatio, contentMode: .fit)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: CornerRadius.medium,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: CornerRadius.medium
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(photo.displayLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.ds.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    if photo.classificationStateValue == .completed {
                        Circle()
                            .fill(ConfidenceLevel(confidence: photo.classificationConfidence).color)
                            .frame(width: 6, height: 6)
                    }
                }

                if let location = photo.effectiveLocation {
                    Text(location)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.ds.textTertiary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, Spacing.space2)
            .padding(.vertical, Spacing.space2)
            .background(Color.ds.surface)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: CornerRadius.medium,
                    bottomTrailingRadius: CornerRadius.medium,
                    topTrailingRadius: 0
                )
            )
        }
        .elevation(.low)
        .loadThumbnail(photo: photo, library: library, image: $image, size: 300)
    }

    // MARK: - Compact Card (3+ columns)

    private var compactCard: some View {
        let cornerRadius = columns >= 4 ? CornerRadius.small : CornerRadius.medium

        return ZStack(alignment: .bottomLeading) {
            ThumbnailImageView(image: image, progressScale: columns >= 4 ? 0.5 : 0.6)
                .aspectRatio(GridTokens.squareAspectRatio, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            if columns <= 3 {
                glassLabel
            }
        }
        .loadThumbnail(photo: photo, library: library, image: $image, size: columns >= 4 ? 150 : 200)
    }

    private var glassLabel: some View {
        Text(photo.displayLabel)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, Spacing.space1 + 2)
            .padding(.vertical, 3)
            .background(.ultraThinMaterial.opacity(0.8))
            .background(Color.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.space1))
            .padding(Spacing.space1)
    }
}

// MARK: - Shared Components

/// Thumbnail image with loading placeholder
private struct ThumbnailImageView: View {
    let image: Image?
    var progressScale: CGFloat = 1.0

    var body: some View {
        Color.clear
            .overlay {
                if let image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.ds.surfaceSecondary)
                        .overlay {
                            ProgressView()
                                .tint(Color.ds.textTertiary)
                                .scaleEffect(progressScale)
                        }
                }
            }
            .clipped()
    }
}

/// Location label with icon/style based on GPS vs ML prediction
private struct LocationLabel: View {
    let location: String

    var body: some View {
        HStack(spacing: Spacing.space1) {
            if location.hasPrefix("\u{2728}") {
                Text(location)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.ds.aiPrimary)
            } else {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: IconSize.tiny))
                    .foregroundStyle(Color.ds.info)
                Text(location)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.ds.textSecondary)
            }
        }
    }
}

// MARK: - Thumbnail Loading Modifier

private struct ThumbnailLoader: ViewModifier {
    @ObservedObject var photo: PhotoAsset
    @ObservedObject var library: PhotoLibraryStore
    @Binding var image: Image?
    let size: Int

    func body(content: Content) -> some View {
        content
            .task(id: photo.fileName) {
                guard !Task.isCancelled else { return }
                let cgSize = CGSize(width: size, height: size)
                if let platformImage = await library.thumbnail(for: photo, size: cgSize) {
                    guard !Task.isCancelled else { return }
                    image = Image(platformImage: platformImage)
                }
            }
    }
}

extension View {
    func loadThumbnail(photo: PhotoAsset, library: PhotoLibraryStore, image: Binding<Image?>, size: Int) -> some View {
        modifier(ThumbnailLoader(photo: photo, library: library, image: image, size: size))
    }
}

// MARK: - Photo Import Button

struct PhotoImportButton: View {
    @Binding var selection: [PhotosPickerItem]
    let maxSelectionCount: Int

    var body: some View {
        PhotosPicker(selection: $selection, maxSelectionCount: maxSelectionCount, matching: .images) {
            Label("Add Photos", systemImage: "plus")
                .labelStyle(.iconOnly)
                .font(.body.bold())
                .foregroundStyle(Color.ds.secondary)
        }
    }
}
