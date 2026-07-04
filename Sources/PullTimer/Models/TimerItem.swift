import Foundation

struct TimerItem: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    var title: String
    let duration: TimeInterval
    let startedAt: Date
    let endAt: Date
    let notificationID: String
    var reminderID: String?

    init(id: UUID = UUID(), title: String, duration: TimeInterval, startedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.duration = duration
        self.startedAt = startedAt
        self.endAt = startedAt.addingTimeInterval(duration)
        self.notificationID = id.uuidString
        self.reminderID = nil
    }

    var remaining: TimeInterval { max(0, endAt.timeIntervalSinceNow) }
    var isExpired: Bool { remaining <= 0 }

    var formattedRemaining: String { TimeFormatter.shortCountdown(remaining) }
    var formattedDuration: String { TimeFormatter.verbose(duration) }
    var formattedEndTime: String { TimeFormatter.endTime(endAt) }
}
