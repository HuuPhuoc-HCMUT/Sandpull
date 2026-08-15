import Foundation

struct DurationMapper {
    // Dead zone: first stretch of drag = visual feedback only
    static let deadZone: CGFloat = 112

    // Most of the drag is reserved for short timers so duration grows slowly.
    // t = normalized position in (0, 1] after dead zone
    //   t=0.70 → 60 min
    //   t=0.90 → 4 h
    //   t=1.00 → 24 h

    static func toDuration(pixels: CGFloat, screenHeight: CGFloat = 900) -> TimeInterval {
        let usable = max(400, screenHeight - 24) - deadZone
        let effective = pixels - deadZone
        guard effective > 0 else { return 0 }

        let t = min(1.0, Double(effective) / Double(usable))
        let raw: TimeInterval
        if t <= 0.70 {
            raw = (t / 0.70) * 3600                       // 0 – 60 min
        } else if t <= 0.90 {
            raw = 3600 + ((t - 0.70) / 0.20) * 10800     // 1 h – 4 h
        } else {
            raw = 14400 + ((t - 0.90) / 0.10) * 72000    // 4 h – 24 h
        }
        return max(60, (raw / 60).rounded() * 60)
    }

    static func isInDeadZone(_ pixels: CGFloat) -> Bool {
        pixels <= deadZone
    }
}
