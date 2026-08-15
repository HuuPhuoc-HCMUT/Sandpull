import Foundation
import Combine

enum DragFeel: String, CaseIterable, Identifiable {
    case precise
    case balanced
    case fast

    var id: String { rawValue }

    var title: String {
        switch self {
        case .precise: return "Precise"
        case .balanced: return "Balanced"
        case .fast: return "Fast"
        }
    }

    /// Share of the drag used for 0–30 minutes.
    var shortBand: Double {
        switch self {
        case .precise: return 0.55
        case .balanced: return 0.40
        case .fast: return 0.25
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Key {
        static let defaultAddMinutes = "adv.defaultAddMinutes"
        static let deadZone = "adv.deadZone"
        static let maxDurationHours = "adv.maxDurationHours"
        static let dragFeel = "adv.dragFeel"
        static let showMenuBarCountdown = "adv.showMenuBarCountdown"
        static let rotateHourglass = "adv.rotateHourglass"
        static let hapticOnCancel = "adv.hapticOnCancel"
    }

    static let defaultAddMinutesDefault = 15
    static let deadZoneDefault: Double = 112
    static let maxDurationHoursDefault = 24
    static let dragFeelDefault = DragFeel.balanced
    static let showMenuBarCountdownDefault = true
    static let rotateHourglassDefault = true
    static let hapticOnCancelDefault = true

    @Published var defaultAddMinutes: Int {
        didSet { defaults.set(defaultAddMinutes, forKey: Key.defaultAddMinutes) }
    }
    @Published var deadZone: Double {
        didSet { defaults.set(deadZone, forKey: Key.deadZone) }
    }
    @Published var maxDurationHours: Int {
        didSet { defaults.set(maxDurationHours, forKey: Key.maxDurationHours) }
    }
    @Published var dragFeel: DragFeel {
        didSet { defaults.set(dragFeel.rawValue, forKey: Key.dragFeel) }
    }
    @Published var showMenuBarCountdown: Bool {
        didSet { defaults.set(showMenuBarCountdown, forKey: Key.showMenuBarCountdown) }
    }
    @Published var rotateHourglass: Bool {
        didSet { defaults.set(rotateHourglass, forKey: Key.rotateHourglass) }
    }
    @Published var hapticOnCancel: Bool {
        didSet { defaults.set(hapticOnCancel, forKey: Key.hapticOnCancel) }
    }

    var defaultAddDuration: TimeInterval { TimeInterval(defaultAddMinutes * 60) }
    var deadZonePixels: CGFloat { CGFloat(deadZone) }

    private let defaults = UserDefaults.standard

    private init() {
        let d = UserDefaults.standard
        defaultAddMinutes = Self.int(d, Key.defaultAddMinutes, Self.defaultAddMinutesDefault)
        deadZone = Self.double(d, Key.deadZone, Self.deadZoneDefault)
        maxDurationHours = Self.int(d, Key.maxDurationHours, Self.maxDurationHoursDefault)
        dragFeel = DragFeel(rawValue: d.string(forKey: Key.dragFeel) ?? "") ?? Self.dragFeelDefault
        showMenuBarCountdown = Self.bool(d, Key.showMenuBarCountdown, Self.showMenuBarCountdownDefault)
        rotateHourglass = Self.bool(d, Key.rotateHourglass, Self.rotateHourglassDefault)
        hapticOnCancel = Self.bool(d, Key.hapticOnCancel, Self.hapticOnCancelDefault)
    }

    func resetAdvanced() {
        defaultAddMinutes = Self.defaultAddMinutesDefault
        deadZone = Self.deadZoneDefault
        maxDurationHours = Self.maxDurationHoursDefault
        dragFeel = Self.dragFeelDefault
        showMenuBarCountdown = Self.showMenuBarCountdownDefault
        rotateHourglass = Self.rotateHourglassDefault
        hapticOnCancel = Self.hapticOnCancelDefault
    }

    private static func int(_ d: UserDefaults, _ key: String, _ fallback: Int) -> Int {
        d.object(forKey: key) == nil ? fallback : d.integer(forKey: key)
    }

    private static func double(_ d: UserDefaults, _ key: String, _ fallback: Double) -> Double {
        d.object(forKey: key) == nil ? fallback : d.double(forKey: key)
    }

    private static func bool(_ d: UserDefaults, _ key: String, _ fallback: Bool) -> Bool {
        d.object(forKey: key) == nil ? fallback : d.bool(forKey: key)
    }
}
