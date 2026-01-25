//
//  ImagePicker.swift
//  PhotoOrganizer
//
//  Async image loading components
//

import PhotosUI
import SwiftUI

// MARK: - Photo Thumbnail View

struct PhotoThumbnailView: View {
    @EnvironmentObject private var library: PhotoLibraryStore
    @ObservedObject var photo: PhotoAsset
    let size: CGSize

    @State private var image: PlatformImage?

    var body: some View {
        ZStack {
            if let image {
                Image(platformImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.ds.surfaceSecondary)
                ProgressView()
                    .tint(Color.ds.textTertiary)
            }
        }
        .task(id: photo.fileName) {
            image = await library.thumbnail(for: photo, size: size)
        }
    }
}

// MARK: - Photo Full Image View

struct PhotoFullImageView: View {
    @EnvironmentObject private var library: PhotoLibraryStore
    @ObservedObject var photo: PhotoAsset

    @State private var image: PlatformImage?

    var body: some View {
        GeometryReader { geometry in
            if let image {
                Image(platformImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                ZStack {
                    Color.ds.surfaceSecondary
                    ProgressView()
                        .tint(Color.ds.textTertiary)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .task(id: photo.fileName) {
            image = await library.image(for: photo)
        }
    }
}
