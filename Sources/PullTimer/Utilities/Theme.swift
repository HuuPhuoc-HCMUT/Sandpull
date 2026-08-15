import SwiftUI
import AppKit

enum Theme {
    static let accent = Color(red: 0.16, green: 0.50, blue: 0.56)
    static let sand = Color(red: 0.85, green: 0.68, blue: 0.40)
    static let sandDeep = Color(red: 0.76, green: 0.54, blue: 0.28)

    enum NS {
        static let teal = NSColor(calibratedRed: 0.22, green: 0.62, blue: 0.66, alpha: 1)
        static let tealDeep = NSColor(calibratedRed: 0.10, green: 0.38, blue: 0.44, alpha: 1)
        static let sand = NSColor(calibratedRed: 0.85, green: 0.68, blue: 0.40, alpha: 1)
        static let sandLight = NSColor(calibratedRed: 0.94, green: 0.84, blue: 0.62, alpha: 1)
        static let glass = NSColor(calibratedRed: 0.78, green: 0.92, blue: 0.94, alpha: 0.75)
        static let glassDark = NSColor(calibratedRed: 0.07, green: 0.15, blue: 0.18, alpha: 0.90)
        static let brass = NSColor(calibratedRed: 0.62, green: 0.48, blue: 0.28, alpha: 1)
    }
}
