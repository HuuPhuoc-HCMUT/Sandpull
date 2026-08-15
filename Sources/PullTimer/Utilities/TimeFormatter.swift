import Foundation

struct TimeFormatter {
    // Badge compact: "6h 46m", "22m 1s", "42s"
    // No space between number and unit — avoids numericText animation glitch with spaces
    static func shortCountdown(_ interval: TimeInterval) -> String {
        let secs = Int(max(0, interval))
        if secs < 60 {
            return "\(secs)s"
        } else if secs < 3600 {
            let m = secs / 60
            let s = secs % 60
            return s > 0 ? "\(m)m \(s)s" : "\(m)m"
        } else {
            let h = secs / 3600
            let m = (secs % 3600) / 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
    }

    // Menu bar: drop seconds except in the last minute
    static func menuBar(_ interval: TimeInterval) -> String {
        let secs = Int(max(0, interval))
        if secs < 60 { return "\(secs)s" }
        if secs < 3600 { return "\(secs / 60)m" }
        let h = secs / 3600
        let m = (secs % 3600) / 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }

    // Verbose for drag tooltip and save dialog header
    static func verbose(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 2
        let secs = max(60, interval)
        return formatter.string(from: secs) ?? shortCountdown(interval)
    }

    static func endTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
