//
//  LibraryView.swift
//  PhotoOrganizer
//
//  Main library view with photo grid and filtering
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
    @State private var isFabExpanded = true
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Photo Organizer")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
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
        .animation(.easeInOut(duration: AnimationDuration.normal), value: library.isImporting)
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            Color.ds.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                categoryFilterBar
                contentArea
            }

            #if os(iOS)
            floatingActionButton
            #endif
        }
    }

    // MARK: - Grid Control Bar

    private var gridControlBar: some View {
        HStack(spacing: Spacing.space3) {
            CompactGridColumnPicker(columns: $library.gridColumns, range: 2...6)

            Spacer()

            // Reclassify All button
            Button {
                showReclassifyAllConfirm = true
            } label: {
                HStack(spacing: Spacing.space1) {
                    if isReclassifyingAll {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .medium))
                    }
                    Text("Reclassify All")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(isReclassifyingAll ? Color.ds.textTertiary : Color.ds.secondary)
                .padding(.horizontal, Spacing.space3)
                .padding(.vertical, Spacing.space2)
                .background(Color.ds.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
            }
            .buttonStyle(.plain)
            .disabled(isReclassifyingAll || photos.isEmpty)
        }
        .padding(.horizontal, Spacing.space3)
        .padding(.vertical, Spacing.space2)
        .background(Color.ds.background)
        .confirmationDialog(
            "Reclassify All Photos?",
            isPresented: $showReclassifyAllConfirm,
            titleVisibility: .visible
        ) {
            Button("Reclassify \(photos.count) photos") {
                Task {
                    await reclassifyAllPhotos()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will re-analyze all \(photos.count) photos using image classification. This may take a while.")
        }
    }

    // MARK: - Category Filter Bar

    private var categoryFilterBar: some View {
        VStack(spacing: 0) {
            gridControlBar

            CategoryFilterBar(
                categories: categoryItems,
                selectedCategory: $library.selectedCategory
            )
        }
        .background(Color.ds.background)
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        let filtered = library.filteredPhotos(from: photos)
        if filtered.isEmpty {
            emptyStateView
                .frame(maxHeight: .infinity)
        } else {
            PhotoGridView(photos: filtered)
        }
    }

    // MARK: - Floating Action Button (iOS)

    #if os(iOS)
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                PhotosPicker(selection: $pickerSelection, maxSelectionCount: 25, matching: .images) {
                    DynamicFAB(isExpanded: isFabExpanded)
                }
                .padding(.trailing, Spacing.space4)
                .padding(.bottom, Spacing.space4)
            }
        }
    }
    #endif

    // MARK: - Importing Overlay

    @ViewBuilder
    private var importingOverlay: some View {
        if library.isImporting {
            LoadingIndicator("Importing...", style: .toast)
                .padding(.bottom, Spacing.space6 + 56)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Category Items

    private var categoryItems: [CategoryItem] {
        let options = library.categoryOptions(from: photos)
        return options.map { category in
            let count = countPhotos(for: category)
            return CategoryItem(name: category, count: count)
        }
    }

    private func countPhotos(for category: String) -> Int {
        photos.filter { photo in
            if category == "All" {
                return true
            } else if category == "Unclassified" {
                let label = photo.classificationLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
                let hasLocation = photo.city?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                let hasPredicted = photo.predictedLocation?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                return (label?.isEmpty ?? true) && !hasLocation && !hasPredicted
            } else if category.hasPrefix("📍 ") {
                // GPS 위치 카테고리
                let cityName = String(category.dropFirst(2))
                return photo.city?.trimmingCharacters(in: .whitespacesAndNewlines) == cityName
            } else if category.hasPrefix("✨ ") {
                // 예측 위치 카테고리
                let predicted = String(category.dropFirst(2))
                return photo.predictedLocation?.trimmingCharacters(in: .whitespacesAndNewlines) == predicted
            } else {
                // ML 분류 카테고리
                return photo.classificationLabel == category
            }
        }.count
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

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .navigationBarTrailing) {
            EmptyView()
        }
        #elseif os(macOS)
        ToolbarItemGroup(placement: .automatic) {
            CompactGridColumnPicker(columns: $library.gridColumns, range: 2...6)

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
            Task {
                await library.importFiles(from: urls)
            }
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

// MARK: - Dynamic Floating Action Button (iOS)

#if os(iOS)
struct DynamicFAB: View {
    let isExpanded: Bool

    private let collapsedSize: CGFloat = 56
    private let expandedHeight: CGFloat = 48

    var body: some View {
        HStack(spacing: Spacing.space2) {
            Image(systemName: "plus")
                .font(.system(size: IconSize.large, weight: .semibold))
                .foregroundStyle(Color.ds.textOnAccent)

            if isExpanded {
                Text("Add")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.ds.textOnAccent)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .trailing))
                    ))
            }
        }
        .padding(.horizontal, isExpanded ? Spacing.space5 : 0)
        .frame(
            width: isExpanded ? nil : collapsedSize,
            height: isExpanded ? expandedHeight : collapsedSize
        )
        .background(
            LinearGradient(
                colors: [Color.ds.secondary, Color.ds.secondaryVariant],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(isExpanded ? AnyShape(Capsule()) : AnyShape(Circle()))
        .shadow(color: Color.ds.secondary.opacity(0.4), radius: 12, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .animation(Motion.spring(), value: isExpanded)
        .accessibilityLabel("Add photos")
        .accessibilityHint("Double tap to import photos")
    }
}

// MARK: - AnyShape Helper

struct AnyShape: Shape {
    private let path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        path = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        path(rect)
    }
}

// MARK: - Legacy Floating Action Button View

struct FloatingActionButtonView: View {
    let icon: String

    private let size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.ds.secondary, Color.ds.secondaryVariant],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color.ds.secondary.opacity(0.4), radius: 12, x: 0, y: 6)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            Image(systemName: icon)
                .font(.system(size: IconSize.large, weight: .semibold))
                .foregroundStyle(Color.ds.textOnAccent)
        }
        .accessibilityLabel("Add photos")
        .accessibilityHint("Double tap to import photos")
    }
}
#endif
