import SwiftUI
import AppKit

struct PointingHandCursor: ViewModifier {
    func body(content: Content) -> some View {
        content.onHover { inside in
            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}

extension View {
    func pointerCursor() -> some View { modifier(PointingHandCursor()) }
}
