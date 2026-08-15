import SwiftUI

struct ExpiryPopupView: View {
    let item: TimerItem
    let onView: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title.isEmpty ? "Timer Complete" : item.title)
                        .font(.headline)
                    Text("\(item.formattedDuration) — time's up!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "hourglass")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider()

            HStack(spacing: 8) {
                Button("Dismiss") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(CancelButtonStyle())

                Spacer()

                Button("View Tasks") { onView() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(SaveButtonStyle())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .frame(width: 300)
        .background(.regularMaterial)
    }
}
