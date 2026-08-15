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

    /// 0 = just started (sand on top), 1 = elapsed (sand on bottom).
    var elapsedProgress: Double {
        guard duration > 0 else { return 1 }
        if isExpired { return 1 }
        return min(1, max(0, 1 - remaining / duration))
    }

    var displayTitle: String { title.isEmpty ? formattedDuration : title }

    var formattedRemaining: String { TimeFormatter.shortCountdown(remaining) }
    var formattedMenuBar: String { TimeFormatter.menuBar(remaining) }
    var formattedDuration: String { TimeFormatter.verbose(duration) }
    var formattedEndTime: String { TimeFormatter.endTime(endAt) }
}
