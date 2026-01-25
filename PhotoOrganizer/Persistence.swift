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

// MARK: - PlatformImage.swift Content (Merged)
#if canImport(UIKit)
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
typealias PlatformImage = NSImage
#endif

extension PlatformImage {
    var cgImageRepresentation: CGImage? {
        #if canImport(UIKit)
        if let cgImage {
            return cgImage
        }
        if let ciImage {
            return CIContext().createCGImage(ciImage, from: ciImage.extent)
        }
        return nil
        #else
        var rect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &rect, context: nil, hints: nil)
        #endif
    }

    var cgImageOrientation: CGImagePropertyOrientation {
        #if canImport(UIKit)
        return CGImagePropertyOrientation(imageOrientation)
        #else
        return .up
        #endif
    }

    static func from(cgImage: CGImage) -> PlatformImage {
        #if canImport(UIKit)
        return UIImage(cgImage: cgImage)
        #else
        return NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        #endif
    }
}

#if canImport(UIKit)
extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
#endif

#if canImport(SwiftUI)
extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #endif
    }
}
#endif

struct PlatformImageCoder {
    static func image(from data: Data) -> PlatformImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return makeImage(from: source, maxPixelSize: nil)
    }

    static func image(from url: URL) -> PlatformImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return makeImage(from: source, maxPixelSize: nil)
    }

    static func thumbnail(from url: URL, maxPixelSize: Int) -> PlatformImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return makeImage(from: source, maxPixelSize: maxPixelSize)
    }

    static func jpegData(from image: PlatformImage, compressionQuality: CGFloat) -> Data? {
        guard let cgImage = image.cgImageRepresentation else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { return nil }
        let options = [kCGImageDestinationLossyCompressionQuality: compressionQuality] as CFDictionary
        CGImageDestinationAddImage(destination, cgImage, options)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }

    private static func makeImage(from source: CGImageSource, maxPixelSize: Int?) -> PlatformImage? {
        let resolvedMaxPixelSize = maxPixelSize ?? self.maxPixelSize(from: source)
        guard let cgImage = makeCGImage(from: source, maxPixelSize: resolvedMaxPixelSize) else { return nil }
        return PlatformImage.from(cgImage: cgImage)
    }

    private static func makeCGImage(from source: CGImageSource, maxPixelSize: Int?) -> CGImage? {
        guard let maxPixelSize else {
            return CGImageSourceCreateImageAtIndex(source, 0, nil)
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    private static func maxPixelSize(from source: CGImageSource) -> Int? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }
        return max(width, height)
    }
}

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

    static func from(visionLabel: String) -> TravelPlaceCategory {
        let label = visionLabel.lowercased()

        // Beach 관련
        if ["beach", "shore", "coast", "seashore", "sandbar"].contains(where: { label.contains($0) }) {
            return .beach
        }
        // Mountain 관련
        if ["mountain", "hill", "canyon", "cliff", "valley", "alp", "volcano"].contains(where: { label.contains($0) }) {
            return .mountain
        }
        // Forest 관련
        if ["forest", "jungle", "woodland", "tree", "rainforest"].contains(where: { label.contains($0) }) {
            return .forest
        }
        // City 관련
        if ["city", "street", "building", "urban", "downtown", "skyscraper", "bridge", "highway"].contains(where: { label.contains($0) }) {
            return .city
        }
        // Lake 관련
        if ["lake", "river", "waterfall", "pond", "stream", "reservoir"].contains(where: { label.contains($0) }) {
            return .lake
        }
        // Park 관련
        if ["park", "garden", "field", "meadow", "lawn", "plaza"].contains(where: { label.contains($0) }) {
            return .park
        }
        // Indoor 관련
        if ["restaurant", "cafe", "museum", "hotel", "room", "indoor", "interior", "lobby", "kitchen", "bedroom", "bathroom"].contains(where: { label.contains($0) }) {
            return .indoor
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
    @Published var gridColumns: Int = 4  // 그리드 컬럼 수 (2~6)

    // Import progress tracking
    @Published var importProgress: ImportProgress = .idle

    // Save state tracking
    @Published private(set) var saveState: PhotoSaveState = .idle
    private var saveStateResetTask: Task<Void, Never>?

    private let logger = Logger(subsystem: "PhotoOrganizer", category: "PhotoLibraryStore")
    private let imageClassifier = VisionImageClassifier()
    private let locationClassifier = VisionLocationClassifier()

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
        lastError = nil

        defer { isImporting = false }

        for item in items {
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
        lastError = nil

        defer { isImporting = false }

        for url in urls {
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

    func reclassify(_ photo: PhotoAsset) async {
        guard let image = await image(for: photo) else {
            lastError = "Photo file is missing."
            return
        }

        await classify(photo: photo, image: image)
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

    func updateNote(_ note: String, for photo: PhotoAsset) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        photo.note = trimmed.isEmpty ? nil : trimmed
        saveContext()
    }

    func thumbnail(for photo: PhotoAsset, size: CGSize) async -> PlatformImage? {
        guard let fileName = photo.fileName else { return nil }
        let fileStore = self.fileStore
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let image = fileStore.loadThumbnail(named: fileName, size: size)
                DispatchQueue.main.async {  // Main thread로 복귀
                    continuation.resume(returning: image)
                }
            }
        }
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

    func refreshLocation(_ photo: PhotoAsset) async {
        guard photo.hasValidGPS else {
            lastError = "No GPS data available."
            return
        }
        await reverseGeocode(photo: photo)
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
            if result.confidence >= 0.15, result.category != .unknown {
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

    func classify(image: PlatformImage) async throws -> ClassificationResult {
        guard let cgImage = image.cgImageRepresentation else {
            throw VisionClassifierError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let safeContinuation = SafeContinuation(continuation)

            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    Self.logger.error("VNClassifyImageRequest failed: \(error.localizedDescription)")
                    safeContinuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNClassificationObservation],
                      let topResult = results.first else {
                    safeContinuation.resume(throwing: VisionClassifierError.noResults)
                    return
                }

                // Return top classification result (already sorted by confidence)
                Self.logger.info("Classification: \(topResult.identifier) (\(topResult.confidence))")
                safeContinuation.resume(returning: ClassificationResult(
                    label: topResult.identifier,
                    confidence: Double(topResult.confidence)
                ))
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                Self.logger.error("VNImageRequestHandler failed: \(error.localizedDescription)")
                safeContinuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - Vision Location Classifier

final class VisionLocationClassifier: @unchecked Sendable {
    private static let logger = Logger(subsystem: "PhotoOrganizer", category: "VisionLocation")

    // 여행지 관련 키워드 필터 (VNClassifyImageRequest 결과에서 필터링)
    private static let placeKeywords: Set<String> = [
        // Beach
        "beach", "shore", "coast", "seashore", "sandbar", "ocean", "sea",
        // Mountain
        "mountain", "hill", "canyon", "cliff", "valley", "alp", "volcano", "peak",
        // Forest
        "forest", "jungle", "woodland", "rainforest",
        // City
        "street", "building", "skyscraper", "bridge", "highway", "tower",
        // Lake
        "lake", "river", "waterfall", "pond", "stream", "reservoir",
        // Park
        "park", "garden", "field", "meadow", "lawn", "plaza",
        // Indoor
        "restaurant", "cafe", "museum", "hotel", "room", "lobby", "kitchen", "bedroom", "bathroom", "airport"
    ]

    func classify(image: PlatformImage) async throws -> LocationClassificationResult {
        guard let cgImage = image.cgImageRepresentation else {
            throw LocationClassifierError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let safeContinuation = SafeContinuation(continuation)

            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    Self.logger.error("VNClassifyImageRequest failed: \(error.localizedDescription)")
                    safeContinuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNClassificationObservation] else {
                    safeContinuation.resume(throwing: LocationClassifierError.noResults)
                    return
                }

                // 여행지 관련 결과만 필터링 (신뢰도 순 정렬됨)
                let placeResults = results.filter { observation in
                    Self.placeKeywords.contains(observation.identifier.lowercased())
                }

                if let topResult = placeResults.first, topResult.confidence >= 0.15 {
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
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                Self.logger.error("VNImageRequestHandler failed: \(error.localizedDescription)")
                safeContinuation.resume(throwing: error)
            }
        }
    }
}
