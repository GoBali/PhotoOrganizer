//
//  InputField.swift
//  PhotoOrganizer
//
//  Text input field component
//

import SwiftUI

struct InputField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String?
    let isMultiline: Bool
    let onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    init(
        _ placeholder: String,
        text: Binding<String>,
        icon: String? = nil,
        isMultiline: Bool = false,
        onSubmit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isMultiline = isMultiline
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: Spacing.space2) {
            if let icon {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(Color.ds.textTertiary)
            }

            if isMultiline {
                TextField(placeholder, text: $text, axis: .vertical)
                    .typography(.body, color: .ds.textPrimary)
                    .lineLimit(3...6)
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .typography(.body, color: .ds.textPrimary)
                    .focused($isFocused)
                    .onSubmit {
                        onSubmit?()
                    }
            }
        }
        .padding(.horizontal, Spacing.space3)
        .frame(minHeight: ComponentSize.inputHeight)
        .background(Color.ds.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .stroke(isFocused ? Color.ds.secondary : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: AnimationDuration.fast), value: isFocused)
    }
}

// MARK: - Input Field with Button

struct InputFieldWithButton: View {
    let placeholder: String
    @Binding var text: String
    let buttonIcon: String
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: Spacing.space2) {
            InputField(placeholder, text: $text, onSubmit: onSubmit)

            Button(action: onSubmit) {
                Image(systemName: buttonIcon)
                    .font(.body.bold())
            }
            .iconButtonStyle(
                backgroundColor: Color.ds.secondary,
                foregroundColor: Color.ds.textOnAccent
            )
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}

// MARK: - Search Field

struct SearchField: View {
    @Binding var text: String
    let placeholder: String

    init(_ placeholder: String = "Search...", text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        HStack(spacing: Spacing.space2) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundStyle(Color.ds.textTertiary)

            TextField(placeholder, text: $text)
                .typography(.body, color: .ds.textPrimary)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(Color.ds.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.space3)
        .frame(height: ComponentSize.inputHeight)
        .background(Color.ds.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        InputField("Enter text...", text: .constant(""))

        InputField("With icon", text: .constant("Hello"), icon: "tag")

        InputField("Multiline input...", text: .constant("This is a\nmultiline text"), isMultiline: true)

        InputFieldWithButton(
            placeholder: "Add a tag...",
            text: .constant("Nature"),
            buttonIcon: "plus"
        ) {}

        SearchField("Search photos...", text: .constant(""))

        SearchField("Search photos...", text: .constant("Nature"))
    }
    .padding()
    .background(Color.ds.background)
}
