import Foundation

struct TimerItem: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    var title: String
    let duration: TimeInterval
    let startedAt: Date
    let endAt: Date
    let notificationID: String
    var reminderID: String?
    var didNotify: Bool

    init(id: UUID = UUID(), title: String, duration: TimeInterval, startedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.duration = duration
        self.startedAt = startedAt
        self.endAt = startedAt.addingTimeInterval(duration)
        self.notificationID = id.uuidString
        self.reminderID = nil
        self.didNotify = false
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        endAt = try container.decode(Date.self, forKey: .endAt)
        notificationID = try container.decode(String.self, forKey: .notificationID)
        reminderID = try container.decodeIfPresent(String.self, forKey: .reminderID)
        didNotify = try container.decodeIfPresent(Bool.self, forKey: .didNotify) ?? false
    }

    var remaining: TimeInterval { max(0, endAt.timeIntervalSinceNow) }
    var isExpired: Bool { remaining <= 0 }

    var formattedRemaining: String { TimeFormatter.shortCountdown(remaining) }
    var formattedDuration: String { TimeFormatter.verbose(duration) }
    var formattedEndTime: String { TimeFormatter.endTime(endAt) }
}
