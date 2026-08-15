import SwiftUI
import AppKit

struct SaveTimerView: View {
    let onSave: (String, TimeInterval) -> Void
    let onCancel: () -> Void

    @State private var duration: TimeInterval
    @State private var description: String = ""
    @FocusState private var focused: Bool

    private static let minDuration: TimeInterval = 60
    private static let presets: [(label: String, seconds: TimeInterval)] = [
        ("5m", 5 * 60),
        ("10m", 10 * 60),
        ("15m", 15 * 60),
        ("30m", 30 * 60),
        ("1h", 60 * 60)
    ]

    /// When set, the field types this title then saves — used by the help tour.
    let tourAutoTitle: String?

    init(duration: TimeInterval,
         title: String = "",
         tourAutoTitle: String? = nil,
         onSave: @escaping (String, TimeInterval) -> Void,
         onCancel: @escaping () -> Void) {
        self.onSave = onSave
        self.onCancel = onCancel
        self.tourAutoTitle = tourAutoTitle
        _duration = State(initialValue: max(Self.minDuration, duration))
        _description = State(initialValue: title)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            VStack(alignment: .leading, spacing: 8) {
                Text(TimeFormatter.verbose(duration))
                    .font(.headline)
                DurationSlider(duration: $duration)
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
            .padding(.bottom, 12)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Label")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.3)

                LabelChipRow(
                    chips: LabelSuggestions.chips(from: TimerStore.shared.items),
                    selected: description
                ) { chip in
                    description = chip.title
                    if let remembered = chip.duration {
                        duration = remembered
                    }
                }

                TextField("or type your own…", text: $description, axis: .vertical)
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
        .pullPanel()
        .onAppear { focused = tourAutoTitle == nil }
        .task(id: tourAutoTitle) {
            guard let sample = tourAutoTitle else { return }
            await typeAndSave(sample)
        }
    }

    private func typeAndSave(_ sample: String) async {
        description = ""
        try? await Task.sleep(nanoseconds: 1_800_000_000)
        guard !Task.isCancelled else { return }
        for character in sample {
            guard !Task.isCancelled else { return }
            description.append(character)
            try? await Task.sleep(nanoseconds: 220_000_000)
        }
        try? await Task.sleep(nanoseconds: 900_000_000)
        guard !Task.isCancelled else { return }
        onSave(description, duration)
    }
}
