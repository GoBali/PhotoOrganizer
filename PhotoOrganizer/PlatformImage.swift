//
//  PlatformImage.swift
//  PhotoOrganizer
//
//  Created by Shinuk Yi on 5/12/24.
//

import CoreGraphics
import CoreImage
import ImageIO
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

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

    var estimatedMemoryCost: Int {
        guard let cg = cgImageRepresentation else { return 0 }
        return cg.bytesPerRow * cg.height
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
        guard let cgImage = makeCGImage(from: source, maxPixelSize: maxPixelSize) else { return nil }
        return PlatformImage.from(cgImage: cgImage)
    }

    private static func makeCGImage(from source: CGImageSource, maxPixelSize: Int?) -> CGImage? {
        var options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        let resolvedSize = maxPixelSize ?? self.maxPixelSize(from: source)
        if let resolvedSize {
            options[kCGImageSourceThumbnailMaxPixelSize] = resolvedSize
        }
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
