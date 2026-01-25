//
//  AutoSaveIndicator.swift
//  PhotoOrganizer
//
//  Auto-save status indicator component
//

import SwiftUI

// MARK: - Save State

enum SaveState: Equatable {
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

    var icon: String? {
        switch self {
        case .idle: return nil
        case .saving: return nil
        case .saved: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .idle: return .clear
        case .saving: return Color.ds.textTertiary
        case .saved: return Color.ds.success
        case .failed: return Color.ds.error
        }
    }

    var shouldShow: Bool {
        switch self {
        case .idle: return false
        default: return true
        }
    }
}

// MARK: - Auto Save Indicator

struct AutoSaveIndicator: View {
    let state: SaveState

    var body: some View {
        Group {
            if state.shouldShow {
                HStack(spacing: Spacing.space1) {
                    if state == .saving {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(state.color)
                    } else if let icon = state.icon {
                        Image(systemName: icon)
                            .font(.system(size: IconSize.small))
                            .foregroundStyle(state.color)
                    }

                    Text(state.text)
                        .typography(.caption2, color: state.color)
                }
                .padding(.horizontal, Spacing.space2)
                .padding(.vertical, Spacing.space1)
                .background(state.color.opacity(Opacity.subtle))
                .clipShape(Capsule())
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .animation(.easeInOut(duration: AnimationDuration.fast), value: state)
        .accessibilityLabel(state.text)
        .accessibilityAddTraits(state == .failed("") ? [.updatesFrequently] : [])
    }
}

// MARK: - Inline Save Indicator

struct InlineSaveIndicator: View {
    let state: SaveState

    var body: some View {
        HStack(spacing: Spacing.space1) {
            if state.shouldShow {
                if state == .saving {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(state.color)
                } else if let icon = state.icon {
                    Image(systemName: icon)
                        .font(.system(size: IconSize.tiny))
                        .foregroundStyle(state.color)
                }

                Text(state.text)
                    .typography(.caption2, color: state.color)
            }
        }
        .animation(.easeInOut(duration: AnimationDuration.fast), value: state)
    }
}

// MARK: - Save State Manager

@MainActor
final class SaveStateManager: ObservableObject {
    @Published private(set) var state: SaveState = .idle

    private var resetTask: Task<Void, Never>?

    func setSaving() {
        resetTask?.cancel()
        state = .saving
    }

    func setSaved() {
        state = .saved
        scheduleReset()
    }

    func setFailed(_ message: String = "Failed to save") {
        state = .failed(message)
        scheduleReset(after: 3.0)
    }

    func reset() {
        resetTask?.cancel()
        state = .idle
    }

    private func scheduleReset(after delay: TimeInterval = 2.0) {
        resetTask?.cancel()
        resetTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            state = .idle
        }
    }
}

// MARK: - Preview

#Preview("Save Indicators") {
    VStack(spacing: 24) {
        Text("Auto Save Indicator")
            .typography(.headline)

        HStack(spacing: 16) {
            AutoSaveIndicator(state: .saving)
            AutoSaveIndicator(state: .saved)
            AutoSaveIndicator(state: .failed("Error"))
        }

        Divider()

        Text("Inline Indicator")
            .typography(.headline)

        HStack {
            Text("Notes")
                .typography(.body)
            Spacer()
            InlineSaveIndicator(state: .saving)
        }
        .padding()
        .background(Color.ds.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))

        HStack {
            Text("Tags")
                .typography(.body)
            Spacer()
            InlineSaveIndicator(state: .saved)
        }
        .padding()
        .background(Color.ds.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    .padding()
    .background(Color.ds.background)
}
