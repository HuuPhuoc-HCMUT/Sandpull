import SwiftUI

struct ExpiryPopupView: View {
    let item: TimerItem
    let onView: () -> Void
    let onDismiss: () -> Void
    let onSnooze: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 34, height: 34)
                    Image(systemName: "hourglass")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title.isEmpty ? "Timer Complete" : item.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text("\(item.formattedDuration) — time's up")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.primary.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .hoverable()
            }

            HStack(spacing: 8) {
                snoozeButton(minutes: 5)
                snoozeButton(minutes: 10)
                Spacer()
                Button("View") { onView() }
                    .buttonStyle(SaveButtonStyle())
            }
        }
        .padding(12)
        .frame(width: 320)
        .pullPanel()
    }

    private func snoozeButton(minutes: Int) -> some View {
        Button("+\(minutes) min") { onSnooze(minutes) }
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Theme.sand.opacity(0.48)))
            .foregroundStyle(Theme.sandDeep)
            .buttonStyle(.plain)
            .hoverable()
    }
}
