//
//  ZoomableImageView.swift
//  PhotoOrganizer
//
//  Zoomable image view with pinch, double-tap, and panning support
//

import SwiftUI

// MARK: - Main Entry Point

struct ZoomableImageView: View {
    let platformImage: PlatformImage

    var body: some View {
        #if os(iOS)
        ZoomableImageViewiOS(image: platformImage)
        #else
        ZoomableImageViewMacOS(image: Image(nsImage: platformImage))
        #endif
    }
}

// MARK: - iOS Implementation (UIScrollView-based)

#if os(iOS)
import UIKit

// MARK: - Custom ScrollView for Layout Callbacks

private class ZoomableScrollView: UIScrollView {
    var onLayoutSubviews: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayoutSubviews?()
    }
}

// MARK: - ZoomableImageViewiOS

struct ZoomableImageViewiOS: UIViewRepresentable {
    let image: UIImage

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = ZoomableScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = maxScale
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.bounces = true
        scrollView.backgroundColor = .clear

        // ImageView 설정 - 초기 frame과 contentSize 설정 (핀치 줌 동작에 필수)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.tag = 100  // 나중에 찾기 위한 태그

        // 초기 frame을 이미지 원본 크기로 설정 (줌 제스처 인식에 필요)
        imageView.frame = CGRect(origin: .zero, size: image.size)
        scrollView.contentSize = image.size
        scrollView.addSubview(imageView)

        // 더블탭 제스처 추가
        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        context.coordinator.scrollView = scrollView
        context.coordinator.imageView = imageView

        // layoutSubviews 콜백 연결 - 스크롤 뷰 크기가 결정된 후 레이아웃 업데이트
        let coordinator = context.coordinator
        scrollView.onLayoutSubviews = { [weak coordinator] in
            coordinator?.updateLayoutIfNeeded()
        }

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // 이미지가 변경되었을 때 업데이트
        if let imageView = scrollView.viewWithTag(100) as? UIImageView {
            if imageView.image !== image {
                imageView.image = image
                context.coordinator.resetZoom()
            }
        }

        // 레이아웃 즉시 업데이트 (layoutSubviews 콜백이 주요 레이아웃 담당)
        context.coordinator.updateLayoutIfNeeded()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(minScale: minScale, maxScale: maxScale)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        weak var scrollView: UIScrollView?
        weak var imageView: UIImageView?

        let minScale: CGFloat
        let maxScale: CGFloat

        // 마지막으로 레이아웃이 적용된 크기 추적
        private var lastLayoutSize: CGSize = .zero

        init(minScale: CGFloat, maxScale: CGFloat) {
            self.minScale = minScale
            self.maxScale = maxScale
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerImageView()
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = scrollView else { return }

            if scrollView.zoomScale > minScale {
                // 현재 확대 상태면 원래 크기로
                scrollView.setZoomScale(minScale, animated: true)
            } else {
                // 탭한 위치를 중심으로 2배 확대
                let location = gesture.location(in: imageView)
                let zoomRect = zoomRectForScale(scale: 2.0, center: location)
                scrollView.zoom(to: zoomRect, animated: true)
            }
        }

        func resetZoom() {
            lastLayoutSize = .zero  // 레이아웃 재계산 강제
            scrollView?.setZoomScale(minScale, animated: false)
            updateLayoutIfNeeded()
        }

        /// 스크롤 뷰 크기가 변경된 경우에만 레이아웃 업데이트
        func updateLayoutIfNeeded() {
            guard let scrollView = scrollView else { return }

            let currentSize = scrollView.bounds.size
            guard currentSize.width > 0 && currentSize.height > 0 else { return }

            // 크기가 변경되지 않았으면 스킵
            guard currentSize != lastLayoutSize else { return }
            lastLayoutSize = currentSize

            updateLayout()
        }

        private func updateLayout() {
            guard let scrollView = scrollView,
                  let imageView = imageView,
                  let image = imageView.image else { return }

            let scrollViewSize = scrollView.bounds.size
            guard scrollViewSize.width > 0 && scrollViewSize.height > 0 else { return }

            // 이미지 뷰 크기를 스크롤 뷰에 맞춤
            let imageSize = image.size
            let widthRatio = scrollViewSize.width / imageSize.width
            let heightRatio = scrollViewSize.height / imageSize.height
            let scale = min(widthRatio, heightRatio)

            let newWidth = imageSize.width * scale
            let newHeight = imageSize.height * scale

            imageView.frame = CGRect(
                x: (scrollViewSize.width - newWidth) / 2,
                y: (scrollViewSize.height - newHeight) / 2,
                width: newWidth,
                height: newHeight
            )

            scrollView.contentSize = imageView.frame.size
            centerImageView()
        }

        private func centerImageView() {
            guard let scrollView = scrollView,
                  let imageView = imageView else { return }

            let scrollViewSize = scrollView.bounds.size
            let imageViewSize = imageView.frame.size

            let horizontalPadding = max(0, (scrollViewSize.width - imageViewSize.width) / 2)
            let verticalPadding = max(0, (scrollViewSize.height - imageViewSize.height) / 2)

            scrollView.contentInset = UIEdgeInsets(
                top: verticalPadding,
                left: horizontalPadding,
                bottom: verticalPadding,
                right: horizontalPadding
            )
        }

        private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
            guard let scrollView = scrollView else { return .zero }

            let size = CGSize(
                width: scrollView.bounds.width / scale,
                height: scrollView.bounds.height / scale
            )

            return CGRect(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2,
                width: size.width,
                height: size.height
            )
        }
    }
}
#endif

// MARK: - macOS Implementation (SwiftUI Gestures)

#if os(macOS)
struct ZoomableImageViewMacOS: View {
    let image: Image

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0

    var body: some View {
        GeometryReader { geometry in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    SimultaneousGesture(
                        magnificationGesture,
                        dragGesture(in: geometry)
                    )
                )
                .gesture(doubleTapGesture(in: geometry))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
        .background(Color.ds.background)
    }

    // MARK: - Gestures

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = lastScale * value
                scale = min(max(newScale, minScale), maxScale)
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= minScale {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        scale = minScale
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
    }

    private func dragGesture(in geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > minScale else { return }

                let newOffset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )

                let maxOffset = calculateMaxOffset(for: geometry)
                offset = CGSize(
                    width: min(max(newOffset.width, -maxOffset.width), maxOffset.width),
                    height: min(max(newOffset.height, -maxOffset.height), maxOffset.height)
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func doubleTapGesture(in geometry: GeometryProxy) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if scale > minScale {
                        // Reset to original
                        scale = minScale
                        lastScale = minScale
                        offset = .zero
                        lastOffset = .zero
                    } else {
                        // Zoom to 2x
                        scale = 2.0
                        lastScale = 2.0
                    }
                }
            }
    }

    private func calculateMaxOffset(for geometry: GeometryProxy) -> CGSize {
        let scaledWidth = geometry.size.width * scale
        let scaledHeight = geometry.size.height * scale

        return CGSize(
            width: max(0, (scaledWidth - geometry.size.width) / 2),
            height: max(0, (scaledHeight - geometry.size.height) / 2)
        )
    }
}
#endif

// MARK: - Async Zoomable Image View

struct AsyncZoomableImageView<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder

    @State private var loadedImage: PlatformImage?
    @State private var isLoading = true

    init(url: URL?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                ZoomableImageView(platformImage: image)
            } else {
                placeholder()
            }
        }
        .task {
            await loadImage()
        }
    }

    @MainActor
    private func loadImage() async {
        guard let url else {
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            #if os(iOS)
            if let uiImage = UIImage(data: data) {
                loadedImage = uiImage
            }
            #elseif os(macOS)
            if let nsImage = NSImage(data: data) {
                loadedImage = nsImage
            }
            #endif
        } catch {
            // Handle error silently
        }

        isLoading = false
    }
}

// MARK: - Legacy Initializer (for backward compatibility)

extension ZoomableImageView {
    init(image: Image) {
        // 이 초기화는 macOS에서만 사용되어야 함
        // iOS에서는 platformImage를 사용하는 것이 권장됨
        #if os(iOS)
        // iOS에서 Image → UIImage 변환은 불가능하므로 placeholder 사용
        self.platformImage = UIImage()
        #else
        // macOS에서는 Image를 직접 사용할 수 없으므로 빈 이미지 사용
        self.platformImage = NSImage()
        #endif
    }
}

// MARK: - Preview

#Preview("Zoomable Image") {
    #if os(iOS)
    if let image = UIImage(systemName: "photo.fill") {
        ZoomableImageView(platformImage: image)
            .frame(height: 400)
            .background(Color.ds.background)
    }
    #else
    if let image = NSImage(systemSymbolName: "photo.fill", accessibilityDescription: nil) {
        ZoomableImageView(platformImage: image)
            .frame(height: 400)
            .background(Color.ds.background)
    }
    #endif
}
