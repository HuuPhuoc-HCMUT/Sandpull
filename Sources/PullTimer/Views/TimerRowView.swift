import SwiftUI

struct TimerRowView: View {
    let item: TimerItem
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayTitle)
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if !item.isExpired { onEdit() }
            }
            .modifier(OptionalHoverable(enabled: !item.isExpired))

            if item.isExpired {
                Button(action: onDelete) {
                    Text("Done")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.sandDeep)
                        .frame(width: 80, height: 26)
                        .background(Capsule().fill(Theme.sand.opacity(0.48)))
                }
                .buttonStyle(.plain)
                .hoverable()
                .layoutPriority(2)
            } else {
                ZStack {
                    Capsule()
                        .fill(Theme.accent.opacity(0.34))
                    Text(item.formattedRemaining)
                        .font(.system(size: 11, weight: .medium).monospacedDigit())
                        .foregroundStyle(Theme.accentDeep)
                        .lineLimit(1)
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.easeInOut(duration: 0.25), value: item.formattedRemaining)
                }
                .frame(width: 80, height: 26)
                .layoutPriority(2)

                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .hoverable()
                .frame(width: 30, alignment: .trailing)
                .layoutPriority(1)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 54, maxHeight: 54)
    }
}
