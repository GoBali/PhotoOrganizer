//
//  ZoomableImageView.swift
//  PhotoOrganizer
//
//  Zoomable image view with pinch, double-tap, and panning support
//

import SwiftUI

struct ZoomableImageView: View {
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

// MARK: - Async Zoomable Image View

struct AsyncZoomableImageView<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder

    @State private var loadedImage: Image?
    @State private var isLoading = true

    init(url: URL?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                ZoomableImageView(image: image)
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
                loadedImage = Image(uiImage: uiImage)
            }
            #elseif os(macOS)
            if let nsImage = NSImage(data: data) {
                loadedImage = Image(nsImage: nsImage)
            }
            #endif
        } catch {
            // Handle error silently
        }

        isLoading = false
    }
}

// MARK: - Platform Image Extension

extension ZoomableImageView {
    init(platformImage: PlatformImage) {
        #if os(iOS)
        self.image = Image(uiImage: platformImage)
        #elseif os(macOS)
        self.image = Image(nsImage: platformImage)
        #endif
    }
}

// MARK: - Preview

#Preview("Zoomable Image") {
    ZoomableImageView(image: Image(systemName: "photo.fill"))
        .frame(height: 400)
        .background(Color.ds.background)
}
