//
//  PhotoOrganizerTests.swift
//  PhotoOrganizerTests
//
//  Created by Shinuk Yi on 5/12/24.
//

import CoreGraphics
import XCTest
@testable import PhotoOrganizer

final class PhotoOrganizerTests: XCTestCase {
    func testPhotoFileStoreSaveLoadDelete() throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = PhotoFileStore(baseURL: tempDirectory)

        let image = makeTestImage()
        let fileName = try store.saveImage(image, id: UUID())

        XCTAssertNotNil(store.loadImage(named: fileName))

        try store.deleteImage(named: fileName)
        XCTAssertNil(store.loadImage(named: fileName))
    }

    private func makeTestImage() -> PlatformImage {
        let width = 4
        let height = 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerRow = width * 4

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            preconditionFailure("Failed to create CGContext.")
        }

        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        guard let cgImage = context.makeImage() else {
            preconditionFailure("Failed to create CGImage.")
        }

        return PlatformImage.from(cgImage: cgImage)
    }
}
