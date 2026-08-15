import SwiftUI

struct DurationSlider: View {
    @Binding var duration: TimeInterval

    private var progress: Binding<Double> {
        Binding(
            get: { DurationMapper.normalized(from: duration) },
            set: { duration = DurationMapper.duration(normalized: $0) }
        )
    }

    private var onClock: Bool {
        DurationMapper.clockQuarterSlot(for: duration) != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text(TimeFormatter.menuBar(duration))
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundStyle(onClock ? Theme.sandDeep : .primary)
                Spacer()
                Text(TimeFormatter.endTime(Date().addingTimeInterval(duration)))
                    .font(.system(size: 11, weight: onClock ? .semibold : .regular))
                    .foregroundStyle(onClock ? Theme.sandDeep : .secondary)
            }
            Slider(value: progress, in: 0...1)
                .tint(onClock ? Theme.sand : Theme.accent)
                .controlSize(.small)
        }
    }
}
