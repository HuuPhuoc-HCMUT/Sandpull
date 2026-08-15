import SwiftUI
import AppKit

enum Theme {
    static let accent = Color(red: 0.22, green: 0.56, blue: 0.62)
    static let accentDeep = Color(red: 0.12, green: 0.40, blue: 0.46)
    static let sand = Color(red: 0.82, green: 0.62, blue: 0.32)
    static let sandDeep = Color(red: 0.58, green: 0.38, blue: 0.14)
    static let panelWash = Color(red: 0.97, green: 0.95, blue: 0.90).opacity(0.55)

    enum NS {
        static let teal = NSColor(calibratedRed: 0.36, green: 0.76, blue: 0.80, alpha: 1)
        static let tealDeep = NSColor(calibratedRed: 0.18, green: 0.52, blue: 0.58, alpha: 1)
        static let sand = NSColor(calibratedRed: 0.90, green: 0.74, blue: 0.46, alpha: 1)
        static let sandLight = NSColor(calibratedRed: 0.97, green: 0.88, blue: 0.68, alpha: 1)
        static let glass = NSColor(calibratedRed: 0.86, green: 0.95, blue: 0.96, alpha: 0.88)
        static let glassDark = NSColor(calibratedRed: 0.16, green: 0.28, blue: 0.32, alpha: 0.88)
        static let glassPanel = NSColor(calibratedRed: 0.22, green: 0.36, blue: 0.40, alpha: 0.90)
        static let brass = NSColor(calibratedRed: 0.70, green: 0.56, blue: 0.34, alpha: 1)
    }
}

extension View {
    func pullPanel() -> some View {
        background {
            ZStack {
                Theme.panelWash
                Rectangle().fill(.regularMaterial)
            }
        }
    }
}
