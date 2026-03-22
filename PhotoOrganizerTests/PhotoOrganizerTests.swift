//
//  PhotoOrganizerTests.swift
//  PhotoOrganizerTests
//
//  Created by Shinuk Yi on 5/12/24.
//

import CoreGraphics
import Vision
import XCTest
@testable import PhotoOrganizer

final class PhotoOrganizerTests: XCTestCase {

    // MARK: - VNClassifyImageRequest 분류 테스트

    /// VNClassifyImageRequest가 다양한 색상 이미지에 대해 결과를 반환하는지 검증
    func testVNClassifyImageRequestReturnsResults() throws {
        let testCases: [(name: String, color: CGColor)] = [
            ("red", CGColor(red: 1, green: 0, blue: 0, alpha: 1)),
            ("blue_sky", CGColor(red: 0.4, green: 0.7, blue: 1, alpha: 1)),
            ("green_nature", CGColor(red: 0.1, green: 0.6, blue: 0.2, alpha: 1)),
        ]

        for testCase in testCases {
            let image = makeColorImage(color: testCase.color, width: 300, height: 300)
            guard let cgImage = image.cgImageRepresentation else {
                XCTFail("CGImage conversion failed for \(testCase.name)")
                continue
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNClassifyImageRequest()
            #if targetEnvironment(simulator) || os(macOS)
            request.usesCPUOnly = true
            #endif

            try handler.perform([request])

            let results = request.results ?? []
            XCTAssertFalse(results.isEmpty, "\(testCase.name): 분류 결과가 비어있음")

            // 결과가 confidence 내림차순인지 확인
            let confidences = results.map { $0.confidence }
            let isSorted = zip(confidences, confidences.dropFirst()).allSatisfy { $0 >= $1 }
            XCTAssertTrue(isSorted, "\(testCase.name): 결과가 confidence 내림차순이 아님")
        }
    }

    /// 파란 하늘 이미지에서 umbrella 라벨("outdoor") 대신 구체적인 라벨을 반환하는지 검증
    func testClassifierSkipsUmbrellaLabels() async throws {
        let classifier = VisionImageClassifier()

        // 파란 하늘색 이미지 (높은 confidence로 분류됨)
        let image = makeColorImage(
            color: CGColor(red: 0.4, green: 0.7, blue: 1, alpha: 1),
            width: 300, height: 300
        )

        let result = try await classifier.classify(image: image)

        // "outdoor" 같은 umbrella 라벨이 아닌 구체적 라벨이 반환되어야 함
        XCTAssertFalse(
            VisionImageClassifier.umbrellaLabels.contains(result.label),
            "분류 결과가 umbrella 라벨('\(result.label)')이면 안 됨 - 더 구체적인 라벨이 필요"
        )
        XCTAssertGreaterThan(result.confidence, 0, "Confidence가 0보다 커야 함")
    }

    /// 낮은 confidence 이미지에서도 결과를 반환하는지 검증
    func testClassifierHandlesLowConfidenceImages() async throws {
        let classifier = VisionImageClassifier()

        // 단색 빨간 이미지 (분류기가 판단하기 어려운 이미지)
        let image = makeColorImage(
            color: CGColor(red: 1, green: 0, blue: 0, alpha: 1),
            width: 300, height: 300
        )

        let result = try await classifier.classify(image: image)

        // 결과가 반환되고 confidence가 0보다 큰지만 확인
        XCTAssertFalse(result.label.isEmpty, "라벨이 비어있으면 안 됨")
        XCTAssertGreaterThan(result.confidence, 0, "Confidence가 0보다 커야 함")
    }

    // MARK: - PhotoFileStore 테스트

    func testPhotoFileStoreSaveLoadDelete() throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = PhotoFileStore(baseURL: tempDirectory)

        let image = makeTestImage()
        let fileName = try store.saveImage(image, id: UUID())

        XCTAssertNotNil(store.loadImage(named: fileName))

        try store.deleteImage(named: fileName)
        XCTAssertNil(store.loadImage(named: fileName))
    }

    // MARK: - Helper Methods

    private func makeColorImage(color: CGColor, width: Int, height: Int) -> PlatformImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            preconditionFailure("Failed to create CGContext.")
        }
        context.setFillColor(color)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let cgImage = context.makeImage() else {
            preconditionFailure("Failed to create CGImage.")
        }
        return PlatformImage.from(cgImage: cgImage)
    }

    private func makeTestImage() -> PlatformImage {
        return makeColorImage(
            color: CGColor(red: 1, green: 0, blue: 0, alpha: 1),
            width: 4, height: 4
        )
    }
}
