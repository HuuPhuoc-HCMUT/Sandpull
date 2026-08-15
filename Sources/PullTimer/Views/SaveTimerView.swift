import SwiftUI
import AppKit

struct SaveTimerView: View {
    let onSave: (String, TimeInterval) -> Void
    let onCancel: () -> Void

    @State private var duration: TimeInterval
    @State private var description: String = ""
    @FocusState private var focused: Bool

    private static let minDuration: TimeInterval = 60
    private static let maxDuration: TimeInterval = 24 * 3600
    private static let presets: [(label: String, seconds: TimeInterval)] = [
        ("5m", 5 * 60),
        ("10m", 10 * 60),
        ("15m", 15 * 60),
        ("30m", 30 * 60),
        ("1h", 60 * 60)
    ]

    init(duration: TimeInterval,
         onSave: @escaping (String, TimeInterval) -> Void,
         onCancel: @escaping () -> Void) {
        self.onSave = onSave
        self.onCancel = onCancel
        _duration = State(initialValue: max(Self.minDuration, duration))
    }

    private var endDate: Date {
        Date().addingTimeInterval(duration)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(TimeFormatter.verbose(duration))
                        .font(.headline)
                    Text(TimeFormatter.endTime(endDate))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    stepButton(systemName: "minus") { adjust(-60) }
                    stepButton(systemName: "plus") { adjust(60) }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 12)

            HStack(spacing: 6) {
                ForEach(Self.presets, id: \.label) { preset in
                    Button(preset.label) { duration = preset.seconds }
                        .buttonStyle(PresetChipStyle(isSelected: abs(duration - preset.seconds) < 1))
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 14)

            Divider()

            VStack(alignment: .leading, spacing: 5) {
                Text("Description")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.3)

                TextField("e.g. Take a break, Call mom…", text: $description, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .lineLimit(1...3)
                    .focused($focused)
                    .onSubmit { onSave(description, duration) }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 13)

            Divider()

            HStack(spacing: 8) {
                Button("Cancel") { onCancel() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(CancelButtonStyle())

                Spacer()

                Button("Save") { onSave(description, duration) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(SaveButtonStyle())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .frame(width: 300)
        .background(.regularMaterial)
        .onAppear { focused = true }
    }

    private func adjust(_ delta: TimeInterval) {
        duration = min(Self.maxDuration, max(Self.minDuration, duration + delta))
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(StepButtonStyle())
    }
}

private struct StepButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.primary.opacity(isHovered ? 0.9 : 0.7))
            .background(
                Circle()
                    .fill(Color.primary.opacity(isHovered ? 0.10 : 0.06))
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isHovered)
            .onHover { isHovered = $0 }
            .pointerCursor()
    }
}

private struct PresetChipStyle: ButtonStyle {
    let isSelected: Bool
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected
                          ? Theme.accent.opacity(0.18)
                          : Color.primary.opacity(isHovered ? 0.08 : 0.05))
            )
            .foregroundStyle(isSelected ? Theme.accent : Color.secondary)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .onHover { isHovered = $0 }
            .pointerCursor()
    }
}
