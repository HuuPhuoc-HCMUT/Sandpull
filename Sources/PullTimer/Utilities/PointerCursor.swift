import SwiftUI

/// Clickable controls change appearance on hover — the pointer stays the arrow.
struct HoverableControl: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .brightness(isHovered ? 0.06 : 0)
            .scaleEffect(isHovered ? 1.05 : 1)
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

struct HoverRowBackground: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(Color.primary.opacity(isHovered ? 0.05 : 0))
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

struct OptionalHoverable: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.hoverable()
        } else {
            content
        }
    }
}

extension View {
    func hoverable() -> some View {
        modifier(HoverableControl())
    }

    func hoverRow() -> some View {
        modifier(HoverRowBackground())
    }

    /// Kept as an alias so older call sites still compile.
    func pointerCursor() -> some View {
        hoverable()
    }
}
