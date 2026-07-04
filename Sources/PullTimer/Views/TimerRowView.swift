import SwiftUI

struct TimerRowView: View {
    let item: TimerItem
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Title — compresses first when space is tight
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.isEmpty ? item.formattedDuration : item.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(item.formattedEndTime)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(0)

            Spacer(minLength: 4)

            // Badge — fixed 80×26, never resizes
            ZStack {
                Capsule()
                    .fill(Color.purple.opacity(0.15))
                Text(item.formattedRemaining)
                    .font(.system(size: 11, weight: .medium).monospacedDigit())
                    .foregroundStyle(Color.purple)
                    .lineLimit(1)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.easeInOut(duration: 0.25), value: item.formattedRemaining)
            }
            .frame(width: 80, height: 26)
            .layoutPriority(2)

            // Delete button — fixed 30pt tap area
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .pointerCursor()
            .frame(width: 30, alignment: .trailing)
            .layoutPriority(1)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 54, maxHeight: 54)
    }
}
