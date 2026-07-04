import Foundation

struct DurationMapper {
    // Dead zone: first 24px of drag = no timer started yet (visual feedback only)
    static let deadZone: CGFloat = 56  // ~2cm at 72pt/inch

    // Full usable range after dead zone maps to 1min → 24h
    // t = normalized position in (0, 1] after dead zone
    //   t=0.10 → 30 min   (fine zone for short timers)
    //   t=0.40 → 4 h
    //   t=1.00 → 24 h

    static func toDuration(pixels: CGFloat, screenHeight: CGFloat = 900) -> TimeInterval {
        let usable = max(400, screenHeight - 24) - deadZone
        let effective = pixels - deadZone
        guard effective > 0 else { return 0 }

        let t = min(1.0, Double(effective) / Double(usable))
        let raw: TimeInterval
        if t <= 0.10 {
            raw = (t / 0.10) * 1800                       // 0 – 30 min
        } else if t <= 0.40 {
            raw = 1800 + ((t - 0.10) / 0.30) * 12600     // 30 min – 4 h
        } else {
            raw = 14400 + ((t - 0.40) / 0.60) * 72000    // 4 h – 24 h
        }
        // Snap to nearest minute, minimum 1 minute
        return max(60, (raw / 60).rounded() * 60)
    }

    static func isInDeadZone(_ pixels: CGFloat) -> Bool {
        pixels <= deadZone
    }
}
