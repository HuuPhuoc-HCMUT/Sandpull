import SwiftUI

struct QuitButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12))
            .foregroundStyle(isHovered ? Color.primary : Color.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? 0.08 : 0))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isHovered)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
    }
}

struct CancelButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? 0.08 : (configuration.isPressed ? 0.12 : 0)))
            )
            .foregroundStyle(Color.secondary)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
    }
}

struct SaveButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(Theme.accent.opacity(isHovered ? 0.82 : 1.0))
                    .shadow(color: Theme.accent.opacity(0.4), radius: isHovered ? 7 : 3, y: 2)
            )
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : (isHovered ? 1.03 : 1.0))
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHovered)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
            .contentShape(Capsule())
            .onHover { isHovered = $0 }
    }
}

struct PresetChipStyle: ButtonStyle {
    var isSelected: Bool = false
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
            .contentShape(Capsule())
            .onHover { isHovered = $0 }
    }
}

struct LabelChipRow: View {
    var chips: [LabelChip] = LabelSuggestions.presets.map { LabelChip(title: $0) }
    var selected: String = ""
    let onSelect: (LabelChip) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(chips) { chip in
                    Button(chip.title) { onSelect(chip) }
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: 110)
                        .buttonStyle(PresetChipStyle(isSelected: selected.caseInsensitiveCompare(chip.title) == .orderedSame))
                }
            }
        }
    }
}
