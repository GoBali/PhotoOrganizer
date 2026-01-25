//
//  PrimaryButton.swift
//  PhotoOrganizer
//
//  Primary action button component
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.space2) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.body.bold())
                    }
                    Text(title)
                }
            }
        }
        .primaryButtonStyle()
        .disabled(isLoading)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("Import Photos", icon: "photo.badge.plus") {}
        PrimaryButton("Save Changes") {}
        PrimaryButton("Loading...", isLoading: true) {}
    }
    .padding()
    .background(Color.ds.background)
}
