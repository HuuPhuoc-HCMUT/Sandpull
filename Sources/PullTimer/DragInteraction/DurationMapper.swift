import Foundation

@MainActor
enum DurationMapper {
    static var deadZone: CGFloat { AppSettings.shared.deadZonePixels }

    static func toDuration(pixels: CGFloat, screenHeight: CGFloat = 900) -> TimeInterval {
        let settings = AppSettings.shared
        let usable = max(400, screenHeight - 24) - settings.deadZonePixels
        let effective = pixels - settings.deadZonePixels
        guard effective > 0 else { return 0 }

        let t = min(1.0, Double(effective) / Double(usable))
        let maxSeconds = TimeInterval(settings.maxDurationHours * 3600)
        let raw = mapped(t: t, feel: settings.dragFeel, maxSeconds: maxSeconds)
        let minutePrecise = max(60, (raw / 60).rounded() * 60)
        return alignToClock(min(maxSeconds, minutePrecise), maxSeconds: maxSeconds)
    }

    /// Soft notch toward :00 / :15 / :30 / :45 on the real clock — not 5-minute duration buckets.
    static func alignToClock(
        _ duration: TimeInterval,
        maxSeconds: TimeInterval,
        now: Date = Date()
    ) -> TimeInterval {
        guard duration > 0 else { return 0 }
        let end = now.addingTimeInterval(duration)
        let cal = Calendar.current
        let minute = cal.component(.minute, from: end)
        let second = cal.component(.second, from: end)
        let rem = minute % 15
        let toPrev = TimeInterval(rem * 60 + second)
        let toNext = TimeInterval((15 - rem) * 60 - second)
        let notch: TimeInterval = 70
        var aligned = duration
        if toPrev > 0 && toPrev <= notch && toPrev <= toNext {
            aligned = duration - toPrev
        } else if toNext <= notch {
            aligned = duration + toNext
        }
        return min(maxSeconds, max(60, aligned))
    }

    /// Hour*60+minute when the timer would end on a quarter-hour; otherwise nil.
    static func clockQuarterSlot(for duration: TimeInterval, now: Date = Date()) -> Int? {
        guard duration > 0 else { return nil }
        let end = now.addingTimeInterval(duration)
        let cal = Calendar.current
        let minute = cal.component(.minute, from: end)
        guard minute % 15 == 0, cal.component(.second, from: end) < 2 else { return nil }
        return cal.component(.hour, from: end) * 60 + minute
    }

    static func isInDeadZone(_ pixels: CGFloat) -> Bool {
        pixels <= deadZone
    }

    /// Same curve as drag, for sliders (0...1). Minute-precise, no clock magnet.
    static func duration(normalized t: Double) -> TimeInterval {
        let settings = AppSettings.shared
        let maxSeconds = TimeInterval(settings.maxDurationHours * 3600)
        let raw = mapped(t: min(1, max(0, t)), feel: settings.dragFeel, maxSeconds: maxSeconds)
        return max(60, min(maxSeconds, (raw / 60).rounded() * 60))
    }

    static func normalized(from duration: TimeInterval) -> Double {
        let settings = AppSettings.shared
        let maxSeconds = TimeInterval(settings.maxDurationHours * 3600)
        let target = min(maxSeconds, max(60, duration))
        var lo = 0.0, hi = 1.0
        for _ in 0..<28 {
            let mid = (lo + hi) / 2
            if mapped(t: mid, feel: settings.dragFeel, maxSeconds: maxSeconds) < target {
                lo = mid
            } else {
                hi = mid
            }
        }
        return (lo + hi) / 2
    }

    /// Usable drag after the dead zone, top → bottom:
    ///   short band  →  0–30 min
    ///   then        →  30 min–2 h
    ///   then        →  2 h–8 h  (skipped when max is 8 h)
    ///   remainder   →  8 h–max
    private static func mapped(t: Double, feel: DragFeel, maxSeconds: TimeInterval) -> TimeInterval {
        let t1 = feel.shortBand
        let rest = max(0.01, 1 - t1)
        let reachesLong = maxSeconds > 8 * 3600

        if t <= t1 {
            return (t / t1) * 1800
        }

        if reachesLong {
            let t2 = t1 + rest * 0.42
            let t3 = t2 + rest * 0.33
            if t <= t2 {
                return 1800 + ((t - t1) / (t2 - t1)) * 5400
            }
            if t <= t3 {
                return 7200 + ((t - t2) / (t3 - t2)) * 21600
            }
            return 28800 + ((t - t3) / max(0.01, 1 - t3)) * (maxSeconds - 28800)
        }

        let t2 = t1 + rest * 0.45
        if t <= t2 {
            return 1800 + ((t - t1) / (t2 - t1)) * 5400
        }
        return 7200 + ((t - t2) / max(0.01, 1 - t2)) * (maxSeconds - 7200)
    }
}
