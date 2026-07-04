import SwiftUI
import AppKit

struct SaveTimerView: View {
    let duration: TimeInterval
    let onSave: (String, TimeInterval) -> Void
    let onCancel: () -> Void

    @State private var description: String = ""
    @FocusState private var focused: Bool
    private let endDate: Date

    init(duration: TimeInterval,
         onSave: @escaping (String, TimeInterval) -> Void,
         onCancel: @escaping () -> Void) {
        self.duration = duration
        self.onSave = onSave
        self.onCancel = onCancel
        self.endDate = Date().addingTimeInterval(duration)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(TimeFormatter.verbose(duration))
                        .font(.headline)
                    Text(TimeFormatter.endTime(endDate))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundStyle(.purple)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider()

            // Description field
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

            // Buttons
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
}
