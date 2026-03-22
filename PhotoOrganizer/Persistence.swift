//
//  Persistence.swift
//  PhotoOrganizer
//
//  Created by Shinuk Yi on 5/12/24.
//

import CoreData
import OSLog
import PhotosUI
import SwiftUI
import ImageIO
import CoreML
import Vision
import CoreGraphics
import CoreImage
import UniformTypeIdentifiers
import CoreLocation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - MetadataService
struct MetadataService {
    static func creationDate(from data: Data) -> Date? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return extractDate(from: source)
    }
    
    static func creationDate(from url: URL) -> Date? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return extractDate(from: source)
    }
    
    private static func extractDate(from source: CGImageSource) -> Date? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else { return nil }
        
        let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any]
        let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        
        if let dateString = exif?[kCGImagePropertyExifDateTimeOriginal as String] as? String {
            if let date = parse(dateString) { return date }
        }
        
        if let dateString = tiff?[kCGImagePropertyTIFFDateTime as String] as? String {
            if let date = parse(dateString) { return date }
        }
        
        return nil
    }
    
    private static func parse(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: string)
    }

    // MARK: - GPS Extraction

    static func gpsData(from data: Data) -> GPSMetadata? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return extractGPS(from: source)
    }

    static func gpsData(from url: URL) -> GPSMetadata? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return extractGPS(from: source)
    }

    private static func extractGPS(from source: CGImageSource) -> GPSMetadata? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] else {
            return nil
        }

        guard let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double else {
            return nil
        }

        let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String ?? "N"
        let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String ?? "E"

        let finalLatitude = (latRef == "S") ? -latitude : latitude
        let finalLongitude = (lonRef == "W") ? -longitude : longitude

        return GPSMetadata(latitude: finalLatitude, longitude: finalLongitude)
    }
}

// MARK: - GPS Metadata

struct GPSMetadata {
    let latitude: Double
    let longitude: Double
}

// MARK: - Geocoding Result

struct GeocodingResult {
    let locationName: String?
    let city: String?
    let country: String?
}

// MARK: - GeocodingService

actor GeocodingService {
    static let shared = GeocodingService()

    private let geocoder = CLGeocoder()
    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 1.0  // Apple rate limit

    private init() {}

    func reverseGeocode(latitude: Double, longitude: Double) async throws -> GeocodingResult {
        // Rate limiting
        if let lastTime = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minRequestInterval {
                try await Task.sleep(nanoseconds: UInt64((minRequestInterval - elapsed) * 1_000_000_000))
            }
        }
        lastRequestTime = Date()

        let location = CLLocation(latitude: latitude, longitude: longitude)
        let placemarks = try await geocoder.reverseGeocodeLocation(location)

        guard let placemark = placemarks.first else {
            return GeocodingResult(locationName: nil, city: nil, country: nil)
        }

        // Build location name
        var locationParts: [String] = []
        if let name = placemark.name { locationParts.append(name) }
        if let locality = placemark.locality { locationParts.append(locality) }
        if let country = placemark.country { locationParts.append(country) }

        let locationName = locationParts.isEmpty ? nil : locationParts.joined(separator: ", ")

        return GeocodingResult(
            locationName: locationName,
            city: placemark.locality,
            country: placemark.country
        )
    }
}

// MARK: - PhotoFileStore
struct PhotoFileStore {
    let directoryURL: URL

    static var `default`: PhotoFileStore {
        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return PhotoFileStore(baseURL: baseURL)
    }

    init(baseURL: URL) {
        directoryURL = baseURL.appendingPathComponent("PhotoLibrary", isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    func saveImage(_ image: PlatformImage, id: UUID) throws -> String {
        let fileName = "\(id.uuidString).jpg"
        let url = directoryURL.appendingPathComponent(fileName)
        guard let data = PlatformImageCoder.jpegData(from: image, compressionQuality: 0.9) else {
            throw PhotoFileStoreError.encodingFailed
        }
        try data.write(to: url, options: [.atomic])
        return fileName
    }

    func loadImage(named fileName: String) -> PlatformImage? {
        let url = directoryURL.appendingPathComponent(fileName)
        return PlatformImageCoder.image(from: url)
    }

    func loadThumbnail(named fileName: String, size: CGSize) -> PlatformImage? {
        let url = directoryURL.appendingPathComponent(fileName)
        let maxPixelSize = Int(max(size.width, size.height))
        return PlatformImageCoder.thumbnail(from: url, maxPixelSize: maxPixelSize)
    }

    func deleteImage(named fileName: String) throws {
        let url = directoryURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }
}

enum PhotoFileStoreError: Error {
    case encodingFailed
}

// MARK: - PersistenceController
struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        let sampleTag = Tag(context: viewContext)
        sampleTag.id = UUID()
        sampleTag.createdAt = Date()
        sampleTag.name = "Sample"

        for index in 0..<4 {
            let asset = PhotoAsset(context: viewContext)
            asset.id = UUID()
            asset.createdAt = Date().addingTimeInterval(TimeInterval(-index * 3600))
            asset.fileName = "preview-\(index).jpg"
            asset.classificationLabel = ["beach", "city", "mountain", "street"][index]
            asset.classificationConfidence = 0.85
            asset.classificationState = ClassificationState.completed.rawValue
            asset.addToTags(sampleTag)
        }

        do {
            try viewContext.save()
        } catch {
            let logger = Logger(subsystem: "PhotoOrganizer", category: "Preview")
            logger.error("Preview save failed: \(error.localizedDescription)")
        }

        return controller
    }()

    let container: NSPersistentContainer
    private let logger = Logger(subsystem: "PhotoOrganizer", category: "Persistence")

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PhotoOrganizer")
        loadPersistentStores(inMemory: inMemory)
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    private func loadPersistentStores(inMemory: Bool) {
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        for description in container.persistentStoreDescriptions {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }

        if let error = loadError, !inMemory {
            logger.error("Persistent store failed, using in-memory fallback: \(error.localizedDescription)")
            loadPersistentStores(inMemory: true)
        } else if let error = loadError {
            logger.error("Persistent store failed: \(error.localizedDescription)")
        }
    }
}

enum ClassificationState: Int16 {
    case pending = 0
    case processing = 1
    case completed = 2
    case failed = 3
}

enum GeocodingState: Int16 {
    case none = 0
    case pending = 1
    case processing = 2
    case completed = 3
    case failed = 4
}

// MARK: - Location Prediction State

enum LocationPredictionState: Int16 {
    case none = 0           // GPS 있음 → 예측 불필요
    case pending = 1        // 대기 중
    case processing = 2     // 진행 중
    case completed = 3      // 완료
    case failed = 4         // 실패
}

// MARK: - Travel Place Category

enum TravelPlaceCategory: String, CaseIterable {
    case beach = "Beach"
    case mountain = "Mountain"
    case forest = "Forest"
    case city = "City"
    case lake = "Lake"
    case park = "Park"
    case indoor = "Indoor"
    case unknown = "Unknown"

    /// 카테고리별 키워드 (Vision 라벨 매칭용, 부분 일치)
    var keywords: [String] {
        switch self {
        case .beach: return ["beach", "shore", "coast", "seashore", "sandbar", "ocean", "sea"]
        case .mountain: return ["mountain", "hill", "canyon", "cliff", "valley", "alp", "volcano", "peak"]
        case .forest: return ["forest", "jungle", "woodland", "tree", "rainforest"]
        case .city: return ["city", "street", "building", "urban", "downtown", "skyscraper", "bridge", "highway", "tower"]
        case .lake: return ["lake", "river", "waterfall", "pond", "stream", "reservoir"]
        case .park: return ["park", "garden", "field", "meadow", "lawn", "plaza"]
        case .indoor: return ["restaurant", "cafe", "museum", "hotel", "room", "indoor", "interior", "lobby", "kitchen", "bedroom", "bathroom", "airport"]
        case .unknown: return []
        }
    }

    /// 모든 카테고리의 키워드 통합 (VisionLocationClassifier 필터링용)
    static let allKeywords: Set<String> = {
        var keywords = Set<String>()
        for category in TravelPlaceCategory.allCases where category != .unknown {
            keywords.formUnion(category.keywords)
        }
        return keywords
    }()

    static func from(visionLabel: String) -> TravelPlaceCategory {
        let label = visionLabel.lowercased()
        for category in TravelPlaceCategory.allCases where category != .unknown {
            if category.keywords.contains(where: { label.contains($0) }) {
                return category
            }
        }
        return .unknown
    }
}

// MARK: - Location Classification Result

struct LocationClassificationResult {
    let label: String?
    let confidence: Double
    let category: TravelPlaceCategory
}

enum LocationClassifierError: Error {
    case invalidImage
    case noResults
}

// MARK: - Photo Save State

enum PhotoSaveState: Equatable {
    case idle
    case saving
    case saved
    case failed(String)

    var text: String {
        switch self {
        case .idle: return ""
        case .saving: return "Saving..."
        case .saved: return "Saved"
        case .failed(let message): return message
        }
    }
}

// MARK: - Import Progress

enum ImportProgress: Equatable {
    case idle
    case importing(current: Int, total: Int)
    case completed(count: Int)
    case failed(String)

    var isActive: Bool {
        if case .importing = self { return true }
        return false
    }

    var progress: Double? {
        if case .importing(let current, let total) = self, total > 0 {
            return Double(current) / Double(total)
        }
        return nil
    }
}

// MARK: - Action Results

/// Reclassify 작업 결과
struct ReclassifyResult {
    let success: Bool
    let changed: Bool
}

/// 위치 갱신 작업 결과
struct LocationRefreshResult {
    let success: Bool
    let changed: Bool
}

extension PhotoAsset {
    var tagsArray: [Tag] {
        let set = tags as? Set<Tag> ?? []
        return set.sorted { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }
    }

    var classificationStateValue: ClassificationState {
        get { ClassificationState(rawValue: classificationState) ?? .pending }
        set { classificationState = newValue.rawValue }
    }

    var geocodingStateValue: GeocodingState {
        get { GeocodingState(rawValue: geocodingState) ?? .none }
        set { geocodingState = newValue.rawValue }
    }

    var locationPredictionStateValue: LocationPredictionState {
        get { LocationPredictionState(rawValue: locationPredictionState) ?? .none }
        set { locationPredictionState = newValue.rawValue }
    }

    var hasValidGPS: Bool {
        hasGPSData && (latitude != 0 || longitude != 0)
    }

    var displayLabel: String {
        let label = classificationLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return label.isEmpty ? "Unclassified" : label
    }

    /// 위치 정보가 있으면 우선 표시, 없으면 ML 분류 사용
    /// 우선순위: GPS city > GPS country > ML 예측 위치 > ML 분류
    var effectiveLabel: String {
        // 1순위: GPS 기반 도시
        if let city = city?.trimmingCharacters(in: .whitespacesAndNewlines), !city.isEmpty {
            return city
        }
        // 2순위: GPS 기반 국가
        if let country = country?.trimmingCharacters(in: .whitespacesAndNewlines), !country.isEmpty {
            return country
        }
        // 3순위: ML 예측 위치 (GPS 없을 때)
        if let predicted = predictedLocation?.trimmingCharacters(in: .whitespacesAndNewlines), !predicted.isEmpty {
            return predicted
        }
        // 4순위: ML 분류
        return displayLabel
    }

    /// 예측된 위치 표시 (GPS 없는 사진용)
    var displayPredictedLocation: String? {
        guard !hasGPSData,
              locationPredictionStateValue == .completed,
              let predicted = predictedLocation?.trimmingCharacters(in: .whitespacesAndNewlines),
              !predicted.isEmpty else {
            return nil
        }
        return predicted
    }

    /// 통합 위치 표시: GPS 기반 > ML 예측
    var effectiveLocation: String? {
        // 1순위: GPS 기반 위치
        if hasValidGPS, let location = displayLocation {
            return location
        }
        // 2순위: ML 예측 위치
        if let predicted = displayPredictedLocation {
            return "✨ \(predicted)"
        }
        return nil
    }

    /// 위치 표시 문자열 (상세 뷰용)
    var displayLocation: String? {
        guard hasValidGPS else { return nil }

        if geocodingStateValue == .completed {
            if let locationName = locationName?.trimmingCharacters(in: .whitespacesAndNewlines), !locationName.isEmpty {
                return locationName
            }
            // fallback to city, country
            var parts: [String] = []
            if let city = city?.trimmingCharacters(in: .whitespacesAndNewlines), !city.isEmpty {
                parts.append(city)
            }
            if let country = country?.trimmingCharacters(in: .whitespacesAndNewlines), !country.isEmpty {
                parts.append(country)
            }
            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }

        return nil
    }

    /// 좌표 표시 문자열
    var coordinatesString: String? {
        guard hasValidGPS else { return nil }
        return String(format: "%.6f, %.6f", latitude, longitude)
    }
}

extension Tag {
    var displayName: String {
        (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - PhotoLibraryStore
@MainActor
final class PhotoLibraryStore: ObservableObject {
    @Published var isImporting = false
    @Published var lastError: String?
    @Published var searchText = ""
    @Published var selectedCategory = "All"
    @Published var gridColumns: Int = 1  // 그리드 컬럼 수 (1~4 iOS, 1~6 macOS)

    // Import progress tracking
    @Published var importProgress: ImportProgress = .idle

    // Save state tracking
    @Published private(set) var saveState: PhotoSaveState = .idle
    private var saveStateResetTask: Task<Void, Never>?

    private let logger = Logger(subsystem: "PhotoOrganizer", category: "PhotoLibraryStore")
    private let imageClassifier = VisionImageClassifier()
    private let locationClassifier = VisionLocationClassifier()
    private let thumbnailCache: NSCache<NSString, PlatformImage> = {
        let cache = NSCache<NSString, PlatformImage>()
        cache.countLimit = 200
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        return cache
    }()

    let context: NSManagedObjectContext
    let fileStore: PhotoFileStore

    init(
        context: NSManagedObjectContext,
        fileStore: PhotoFileStore = .default
    ) {
        self.context = context
        self.fileStore = fileStore
    }

    func categoryOptions(from photos: FetchedResults<PhotoAsset>) -> [String] {
        // ML 분류 라벨
        let labels = Set(photos.compactMap { $0.classificationLabel?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty })

        // 위치 카테고리 (도시명) - GPS 기반
        let cities = Set(photos.compactMap { $0.city?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty })
            .map { "📍 \($0)" }

        // 예측 위치 카테고리 - ML 기반
        let predictedLocations = Set(photos.compactMap { $0.predictedLocation?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty })
            .map { "✨ \($0)" }

        return ["All", "Unclassified"] + cities.sorted() + predictedLocations.sorted() + labels.sorted()
    }

    func filteredPhotos(from photos: FetchedResults<PhotoAsset>) -> [PhotoAsset] {
        photos.filter { photo in
            matchesCategory(photo) && matchesSearch(photo)
        }
    }

    private func matchesCategory(_ photo: PhotoAsset) -> Bool {
        switch selectedCategory {
        case "All":
            return true
        case "Unclassified":
            let label = photo.classificationLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
            let hasLocation = photo.city?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            let hasPredicted = photo.predictedLocation?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            return (label?.isEmpty ?? true) && !hasLocation && !hasPredicted
        default:
            // GPS 위치 카테고리 (📍 접두사)
            if selectedCategory.hasPrefix("📍 ") {
                let cityName = String(selectedCategory.dropFirst(2))
                return photo.city?.trimmingCharacters(in: .whitespacesAndNewlines) == cityName
            }
            // 예측 위치 카테고리 (✨ 접두사)
            if selectedCategory.hasPrefix("✨ ") {
                let predicted = String(selectedCategory.dropFirst(2))
                return photo.predictedLocation?.trimmingCharacters(in: .whitespacesAndNewlines) == predicted
            }
            // ML 분류 카테고리
            let label = photo.classificationLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
            return label == selectedCategory
        }
    }

    private func matchesSearch(_ photo: PhotoAsset) -> Bool {
        guard !searchText.isEmpty else { return true }
        let query = searchText.lowercased()

        if photo.displayLabel.lowercased().contains(query) {
            return true
        }

        if let note = photo.note?.lowercased(), note.contains(query) {
            return true
        }

        if let original = photo.originalFilename?.lowercased(), original.contains(query) {
            return true
        }

        // 위치 검색 (GPS 기반)
        if let city = photo.city?.lowercased(), city.contains(query) {
            return true
        }

        if let country = photo.country?.lowercased(), country.contains(query) {
            return true
        }

        if let locationName = photo.locationName?.lowercased(), locationName.contains(query) {
            return true
        }

        // 예측 위치 검색 (ML 기반)
        if let predicted = photo.predictedLocation?.lowercased(), predicted.contains(query) {
            return true
        }

        return photo.tagsArray.contains { $0.displayName.lowercased().contains(query) }
    }

    func importPhotos(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        guard !isImporting else { return }
        isImporting = true
        importProgress = .importing(current: 0, total: items.count)
        lastError = nil

        defer {
            isImporting = false
            importProgress = .idle
        }

        var importedCount = 0
        for (index, item) in items.enumerated() {
            importProgress = .importing(current: index + 1, total: items.count)
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                guard let image = PlatformImageCoder.image(from: data) else { continue }
                let creationDate = MetadataService.creationDate(from: data)
                let gpsData = MetadataService.gpsData(from: data)
                let asset = try persistImportedImage(image, originalFilename: item.itemIdentifier, creationDate: creationDate, gpsData: gpsData)
                await classify(photo: asset, image: image)

                // 2단계 위치 분류: GPS 있으면 역지오코딩, 없으면 ML 예측
                if gpsData != nil {
                    await reverseGeocode(photo: asset)
                } else {
                    await predictLocation(photo: asset, image: image)
                }
                importedCount += 1
            } catch {
                logger.error("Import failed: \(error.localizedDescription)")
                lastError = "Failed to import one or more photos."
            }
        }
    }

    func importFiles(from urls: [URL]) async {
        guard !urls.isEmpty else { return }
        guard !isImporting else { return }
        isImporting = true
        importProgress = .importing(current: 0, total: urls.count)
        lastError = nil

        defer {
            isImporting = false
            importProgress = .idle
        }

        for (index, url) in urls.enumerated() {
            importProgress = .importing(current: index + 1, total: urls.count)
            do {
                #if os(macOS)
                let accessed = url.startAccessingSecurityScopedResource()
                defer {
                    if accessed {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                #endif

                guard let image = PlatformImageCoder.image(from: url) else { continue }
                let creationDate = MetadataService.creationDate(from: url)
                let gpsData = MetadataService.gpsData(from: url)
                let asset = try persistImportedImage(image, originalFilename: url.lastPathComponent, creationDate: creationDate, gpsData: gpsData)
                await classify(photo: asset, image: image)

                // 2단계 위치 분류: GPS 있으면 역지오코딩, 없으면 ML 예측
                if gpsData != nil {
                    await reverseGeocode(photo: asset)
                } else {
                    await predictLocation(photo: asset, image: image)
                }
            } catch {
                logger.error("File import failed: \(error.localizedDescription)")
                lastError = "Failed to import one or more files."
            }
        }
    }

    func reclassify(_ photo: PhotoAsset) async -> ReclassifyResult {
        guard let image = await image(for: photo) else {
            lastError = "Photo file is missing."
            return ReclassifyResult(success: false, changed: false)
        }

        // 이전 값 저장
        let previousLabel = photo.classificationLabel
        let previousConfidence = photo.classificationConfidence

        await classify(photo: photo, image: image)

        // 결과 비교
        let changed = photo.classificationLabel != previousLabel ||
                      abs(photo.classificationConfidence - previousConfidence) > ClassificationThreshold.confidenceChangeDelta
        let success = photo.classificationStateValue == .completed

        return ReclassifyResult(success: success, changed: changed)
    }

    func delete(_ photo: PhotoAsset) {
        let fileName = photo.fileName
        context.delete(photo)
        saveContext()

        if let fileName = fileName {
            do {
                try fileStore.deleteImage(named: fileName)
            } catch {
                logger.error("Delete failed: \(error.localizedDescription)")
                lastError = "Failed to delete photo file."
            }
        }

        cleanupOrphanedTags()
    }

    func addTag(_ name: String, to photo: PhotoAsset) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let request = Tag.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "name =[c] %@", trimmed)

        let tag: Tag
        if let existing = try? context.fetch(request).first {
            tag = existing
        } else {
            let newTag = Tag(context: context)
            newTag.id = UUID()
            newTag.createdAt = Date()
            newTag.name = trimmed
            tag = newTag
        }

        photo.addToTags(tag)
        saveContext()
    }

    func removeTag(_ tag: Tag, from photo: PhotoAsset) {
        photo.removeFromTags(tag)
        saveContext()
        cleanupOrphanedTags()
    }

    /// 모든 태그 이름 목록 (사용 빈도순 정렬)
    func allTagNames() -> [String] {
        let request = Tag.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        guard let tags = try? context.fetch(request) else { return [] }

        // 사용 빈도순으로 정렬 (많이 사용된 태그 먼저)
        let sorted = tags.sorted { ($0.photos?.count ?? 0) > ($1.photos?.count ?? 0) }
        return sorted.compactMap { $0.name }
    }

    /// 현재 사진에 없는 추천 태그 (최대 개수 제한)
    func suggestedTags(for photo: PhotoAsset, limit: Int = 8) -> [String] {
        let existingNames = Set(photo.tagsArray.compactMap { $0.name?.lowercased() })
        return allTagNames()
            .filter { !existingNames.contains($0.lowercased()) }
            .prefix(limit)
            .map { $0 }
    }

    /// 검색어로 태그 필터링 (자동완성용)
    func filterTags(matching query: String, excluding photo: PhotoAsset) -> [String] {
        guard !query.isEmpty else { return [] }
        let lowercasedQuery = query.lowercased()
        let existingNames = Set(photo.tagsArray.compactMap { $0.name?.lowercased() })

        return allTagNames()
            .filter { name in
                let lowercased = name.lowercased()
                return lowercased.contains(lowercasedQuery) && !existingNames.contains(lowercased)
            }
            .prefix(5)
            .map { $0 }
    }

    func updateNote(_ note: String, for photo: PhotoAsset) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        photo.note = trimmed.isEmpty ? nil : trimmed
        saveContext()
    }

    func thumbnail(for photo: PhotoAsset, size: CGSize) async -> PlatformImage? {
        guard let fileName = photo.fileName else { return nil }
        let cacheKey = "\(fileName)_\(Int(size.width))x\(Int(size.height))" as NSString

        if let cached = thumbnailCache.object(forKey: cacheKey) {
            return cached
        }

        let fileStore = self.fileStore
        let image: PlatformImage? = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let image = fileStore.loadThumbnail(named: fileName, size: size)
                DispatchQueue.main.async {
                    continuation.resume(returning: image)
                }
            }
        }

        if let image {
            let cost = image.estimatedMemoryCost
            thumbnailCache.setObject(image, forKey: cacheKey, cost: cost)
        }
        return image
    }

    func image(for photo: PhotoAsset) async -> PlatformImage? {
        guard let fileName = photo.fileName else { return nil }
        let fileStore = self.fileStore
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let image = fileStore.loadImage(named: fileName)
                DispatchQueue.main.async {  // Main thread로 복귀
                    continuation.resume(returning: image)
                }
            }
        }
    }

    func refreshLocation(_ photo: PhotoAsset) async -> LocationRefreshResult {
        guard photo.hasValidGPS else {
            lastError = "No GPS data available."
            return LocationRefreshResult(success: false, changed: false)
        }

        // 이전 값 저장
        let previousCity = photo.city
        let previousCountry = photo.country
        let previousLocationName = photo.locationName

        await reverseGeocode(photo: photo)

        // 결과 비교
        let changed = photo.city != previousCity ||
                      photo.country != previousCountry ||
                      photo.locationName != previousLocationName
        let success = photo.geocodingStateValue == .completed

        return LocationRefreshResult(success: success, changed: changed)
    }

    /// GPS 없는 사진의 위치 재예측
    func repredictLocation(_ photo: PhotoAsset) async {
        guard !photo.hasGPSData else {
            lastError = "Photo has GPS data. Use refresh location instead."
            return
        }

        guard let image = await image(for: photo) else {
            lastError = "Photo file is missing."
            return
        }

        await predictLocation(photo: photo, image: image)
    }

    /// 2차 위치 예측: Vision Framework로 여행지 타입 분류
    private func predictLocation(photo: PhotoAsset, image: PlatformImage) async {
        // GPS 있으면 예측 불필요
        guard !photo.hasGPSData else {
            photo.locationPredictionState = LocationPredictionState.none.rawValue
            saveContext()
            return
        }

        photo.locationPredictionState = LocationPredictionState.processing.rawValue
        saveContext()

        do {
            let result = try await locationClassifier.classify(image: image)

            // 신뢰도 임계값 이상인 경우만 저장
            if result.confidence >= ClassificationThreshold.locationPrediction, result.category != .unknown {
                photo.predictedLocation = result.category.rawValue
                photo.predictedLocationConfidence = result.confidence
                logger.info("Location predicted: \(result.category.rawValue) (\(result.confidence))")
            } else {
                photo.predictedLocation = nil
                photo.predictedLocationConfidence = 0
                logger.info("Location prediction below threshold or unknown")
            }
            photo.locationPredictionState = LocationPredictionState.completed.rawValue
        } catch {
            photo.locationPredictionState = LocationPredictionState.failed.rawValue
            logger.error("Location prediction failed: \(error.localizedDescription)")
        }

        saveContext()
    }

    private func reverseGeocode(photo: PhotoAsset) async {
        guard photo.hasGPSData, photo.latitude != 0 || photo.longitude != 0 else { return }

        photo.geocodingState = GeocodingState.processing.rawValue
        saveContext()

        do {
            let result = try await GeocodingService.shared.reverseGeocode(
                latitude: photo.latitude,
                longitude: photo.longitude
            )

            photo.locationName = result.locationName
            photo.city = result.city
            photo.country = result.country
            photo.geocodingState = GeocodingState.completed.rawValue
            logger.info("Geocoding completed: \(result.city ?? "unknown city"), \(result.country ?? "unknown country")")
        } catch {
            photo.geocodingState = GeocodingState.failed.rawValue
            logger.error("Geocoding failed: \(error.localizedDescription)")
        }

        saveContext()
    }

    private func classify(photo: PhotoAsset, image: PlatformImage) async {
        photo.classificationState = ClassificationState.processing.rawValue
        photo.classificationError = nil
        saveContext()

        do {
            let result = try await imageClassifier.classify(image: image)
            photo.classificationLabel = result.label
            photo.classificationConfidence = result.confidence
            photo.classificationState = ClassificationState.completed.rawValue
            logger.info("Classification completed: \(result.label) (\(result.confidence))")
        } catch {
            photo.classificationState = ClassificationState.failed.rawValue
            photo.classificationError = error.localizedDescription
            logger.error("Classification failed: \(error.localizedDescription)")
        }

        saveContext()
    }

    private func persistImportedImage(_ image: PlatformImage, originalFilename: String?, creationDate: Date? = nil, gpsData: GPSMetadata? = nil) throws -> PhotoAsset {
        let photoID = UUID()
        let fileName = try fileStore.saveImage(image, id: photoID)

        let asset = PhotoAsset(context: context)
        asset.id = photoID
        asset.createdAt = creationDate ?? Date()
        asset.fileName = fileName
        asset.originalFilename = originalFilename
        asset.classificationState = ClassificationState.pending.rawValue
        asset.classificationConfidence = 0

        // GPS 데이터 저장
        if let gps = gpsData {
            asset.hasGPSData = true
            asset.latitude = gps.latitude
            asset.longitude = gps.longitude
            asset.geocodingState = GeocodingState.pending.rawValue
        } else {
            asset.hasGPSData = false
            asset.latitude = 0
            asset.longitude = 0
            asset.geocodingState = GeocodingState.none.rawValue
        }

        saveContext()
        return asset
    }

    private func saveContext() {
        guard context.hasChanges else { return }

        saveStateResetTask?.cancel()
        saveState = .saving

        do {
            try context.save()
            saveState = .saved
            scheduleResetSaveState()
        } catch {
            logger.error("Save failed: \(error.localizedDescription)")
            lastError = "Failed to save changes."
            saveState = .failed("Save failed")
            scheduleResetSaveState(after: 3.0)
        }
    }

    private func scheduleResetSaveState(after delay: TimeInterval = 2.0) {
        saveStateResetTask?.cancel()
        saveStateResetTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            saveState = .idle
        }
    }

    private func cleanupOrphanedTags() {
        let request = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "photos.@count == 0")

        guard let tags = try? context.fetch(request) else { return }
        tags.forEach { context.delete($0) }
        saveContext()
    }
}

// MARK: - Classification Result

struct ClassificationResult {
    let label: String
    let confidence: Double
}

// MARK: - Vision Image Classifier (Apple Built-in - 1000+ categories)

enum VisionClassifierError: Error {
    case invalidImage
    case noResults
}

/// Thread-safe continuation wrapper to prevent double resume
private final class SafeContinuation<T>: @unchecked Sendable {
    private var continuation: CheckedContinuation<T, Error>?
    private let lock = NSLock()

    init(_ continuation: CheckedContinuation<T, Error>) {
        self.continuation = continuation
    }

    func resume(returning value: T) {
        lock.lock()
        defer { lock.unlock() }
        continuation?.resume(returning: value)
        continuation = nil
    }

    func resume(throwing error: Error) {
        lock.lock()
        defer { lock.unlock() }
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

final class VisionImageClassifier: @unchecked Sendable {
    private static let logger = Logger(subsystem: "PhotoOrganizer", category: "VisionImageClassifier")
    private static let classificationQueue = DispatchQueue(label: "com.photoorganizer.classification", qos: .userInitiated)

    /// Apple 분류 체계의 최상위 부모 카테고리 (구체적 의미 부족)
    static let umbrellaLabels: Set<String> = [
        "outdoor", "indoor", "people", "adult", "material",
        "sky", "land", "water", "food_and_drink",
        "animal", "plant", "recreation", "sport"
    ]

    func classify(image: PlatformImage) async throws -> ClassificationResult {
        guard let cgImage = image.cgImageRepresentation else {
            throw VisionClassifierError.invalidImage
        }

        let orientation = image.cgImageOrientation

        return try await withCheckedThrowingContinuation { continuation in
            let safeContinuation = SafeContinuation(continuation)

            // 전용 큐에서 실행하여 handler/request가 완료될 때까지 유지
            Self.classificationQueue.async {
                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
                let request = VNClassifyImageRequest()

                // Simulator/macOS에서는 Neural Engine이 없으므로 CPU만 사용
                #if targetEnvironment(simulator) || os(macOS)
                request.usesCPUOnly = true
                #endif

                do {
                    try handler.perform([request])

                    // perform이 동기적으로 완료된 후 결과 처리
                    guard let results = request.results, !results.isEmpty else {
                        safeContinuation.resume(throwing: VisionClassifierError.noResults)
                        return
                    }

                    // 최고 confidence 근처(1% 이내)의 결과들에서 umbrella 라벨 제외
                    let maxConf = results[0].confidence
                    let threshold = maxConf * 0.99  // 1% tolerance
                    let topBand = results.prefix(while: { $0.confidence >= threshold })

                    // umbrella 라벨 제외하고 가장 구체적인 라벨 선택
                    let specific = topBand.first(where: { !Self.umbrellaLabels.contains($0.identifier) })
                    let topResult = specific ?? results[0]

                    Self.logger.info("Classification: \(topResult.identifier) (\(topResult.confidence))")
                    safeContinuation.resume(returning: ClassificationResult(
                        label: topResult.identifier,
                        confidence: Double(topResult.confidence)
                    ))
                } catch {
                    Self.logger.error("VNImageRequestHandler failed: \(error.localizedDescription)")
                    safeContinuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Vision Location Classifier

final class VisionLocationClassifier: @unchecked Sendable {
    private static let logger = Logger(subsystem: "PhotoOrganizer", category: "VisionLocation")
    private static let classificationQueue = DispatchQueue(label: "com.photoorganizer.location-classification", qos: .userInitiated)

    func classify(image: PlatformImage) async throws -> LocationClassificationResult {
        guard let cgImage = image.cgImageRepresentation else {
            throw LocationClassifierError.invalidImage
        }

        let orientation = image.cgImageOrientation

        return try await withCheckedThrowingContinuation { continuation in
            let safeContinuation = SafeContinuation(continuation)

            Self.classificationQueue.async {
                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
                let request = VNClassifyImageRequest()

                #if targetEnvironment(simulator) || os(macOS)
                request.usesCPUOnly = true
                #endif

                do {
                    try handler.perform([request])

                    guard let results = request.results else {
                        safeContinuation.resume(throwing: LocationClassifierError.noResults)
                        return
                    }

                    // 여행지 관련 결과만 필터링 (TravelPlaceCategory 통합 키워드, 부분 일치)
                    let placeResults = results.filter { observation in
                        let id = observation.identifier.lowercased()
                        return TravelPlaceCategory.allKeywords.contains(where: { id.contains($0) })
                    }

                    if let topResult = placeResults.first, topResult.confidence >= Float(ClassificationThreshold.locationPrediction) {
                        let category = TravelPlaceCategory.from(visionLabel: topResult.identifier)
                        Self.logger.info("Location predicted: \(topResult.identifier) -> \(category.rawValue) (\(topResult.confidence))")
                        safeContinuation.resume(returning: LocationClassificationResult(
                            label: topResult.identifier,
                            confidence: Double(topResult.confidence),
                            category: category
                        ))
                    } else {
                        Self.logger.info("No place-related classification found")
                        safeContinuation.resume(returning: LocationClassificationResult(
                            label: nil,
                            confidence: 0,
                            category: .unknown
                        ))
                    }
                } catch {
                    Self.logger.error("VNImageRequestHandler failed: \(error.localizedDescription)")
                    safeContinuation.resume(throwing: error)
                }
            }
        }
    }
}
