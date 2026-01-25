//
//  Toast.swift
//  PhotoOrganizer
//
//  Toast notification component for feedback
//

import SwiftUI

// MARK: - Toast Style

enum ToastStyle {
    case info
    case success
    case warning
    case error
    case loading

    var backgroundColor: Color {
        switch self {
        case .info: return Color.ds.surface
        case .success: return Color.ds.successBackground
        case .warning: return Color.ds.warningBackground
        case .error: return Color.ds.errorBackground
        case .loading: return Color.ds.surface
        }
    }

    var iconColor: Color {
        switch self {
        case .info: return Color.ds.info
        case .success: return Color.ds.success
        case .warning: return Color.ds.warning
        case .error: return Color.ds.error
        case .loading: return Color.ds.secondary
        }
    }

    var icon: String? {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .loading: return nil
        }
    }

    var textColor: Color {
        switch self {
        case .info: return Color.ds.textPrimary
        case .success: return Color.ds.success
        case .warning: return Color.ds.warning
        case .error: return Color.ds.error
        case .loading: return Color.ds.textPrimary
        }
    }
}

// MARK: - Toast View

struct Toast: View {
    let message: String
    let style: ToastStyle
    let onDismiss: (() -> Void)?

    init(
        _ message: String,
        style: ToastStyle = .info,
        onDismiss: (() -> Void)? = nil
    ) {
        self.message = message
        self.style = style
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(spacing: Spacing.space3) {
            if style == .loading {
                ProgressView()
                    .tint(style.iconColor)
            } else if let icon = style.icon {
                Image(systemName: icon)
                    .font(.system(size: IconSize.large))
                    .foregroundStyle(style.iconColor)
            }

            Text(message)
                .font(.callout.weight(.medium))
                .foregroundStyle(style.textColor)
                .lineLimit(2)

            Spacer(minLength: 0)

            if let onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: IconSize.small, weight: .bold))
                        .foregroundStyle(Color.ds.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.space4)
        .padding(.vertical, Spacing.space3)
        .background(style.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .elevation(.medium)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(style == .error ? "Error" : style == .warning ? "Warning" : "Info"): \(message)")
    }
}

// MARK: - Toast Container

struct ToastContainer<Content: View>: View {
    @Binding var toast: ToastData?
    let content: Content

    init(toast: Binding<ToastData?>, @ViewBuilder content: () -> Content) {
        self._toast = toast
        self.content = content()
    }

    var body: some View {
        ZStack {
            content

            VStack {
                Spacer()

                if let toast {
                    Toast(toast.message, style: toast.style) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            self.toast = nil
                        }
                    }
                    .padding(.horizontal, Spacing.space4)
                    .padding(.bottom, Spacing.space6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: toast != nil)
    }
}

// MARK: - Toast Data

struct ToastData: Equatable {
    let id = UUID()
    let message: String
    let style: ToastStyle
    let duration: TimeInterval?

    init(_ message: String, style: ToastStyle = .info, duration: TimeInterval? = 3.0) {
        self.message = message
        self.style = style
        self.duration = duration
    }

    static func == (lhs: ToastData, rhs: ToastData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastData?

    func body(content: Content) -> some View {
        ToastContainer(toast: $toast) {
            content
        }
        .onChange(of: toast) { _, newValue in
            guard let newValue, let duration = newValue.duration else { return }
            Task {
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                await MainActor.run {
                    if self.toast?.id == newValue.id {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            self.toast = nil
                        }
                    }
                }
            }
        }
    }
}

extension View {
    func toast(_ toast: Binding<ToastData?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

// MARK: - Preview

#Preview("Toast Styles") {
    VStack(spacing: 16) {
        Toast("This is an info message", style: .info)
        Toast("Successfully saved!", style: .success)
        Toast("Please check your input", style: .warning)
        Toast("Something went wrong", style: .error)
        Toast("Loading...", style: .loading)
        Toast("Dismissible toast", style: .info) {}
    }
    .padding()
    .background(Color.ds.background)
}
