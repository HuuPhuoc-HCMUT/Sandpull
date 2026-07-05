import Foundation

/// Mock provider — generates fresh events relative to the current time on every call.
/// Replace with AppleCalendarProvider / GoogleCalendarProvider without touching UI code.
@MainActor
final class MockCalendarProvider: CalendarProvider {
    static let shared = MockCalendarProvider()
    private init() {}

    func eventsStartingNow(within horizon: TimeInterval) -> [CalendarEvent] {
        let now = Date()
        let cutoff = now.addingTimeInterval(horizon)

        let events = [
            CalendarEvent(
                id: UUID(),
                title: "Sprint Review",
                startDate: now.addingTimeInterval(60 * 60),             // +1h
                endDate:   now.addingTimeInterval(60 * 60 + 30 * 60)   // +1h30m
            ),
            CalendarEvent(
                id: UUID(),
                title: "Coffee Chat",
                startDate: now.addingTimeInterval(2 * 60 * 60),          // +2h
                endDate:   now.addingTimeInterval(2 * 60 * 60 + 20 * 60) // +2h20m
            ),
            CalendarEvent(
                id: UUID(),
                title: "Design Review",
                startDate: now.addingTimeInterval(4 * 60 * 60),          // +4h
                endDate:   now.addingTimeInterval(4 * 60 * 60 + 45 * 60) // +4h45m
            ),
        ]
        return events.filter { $0.startDate <= cutoff }
    }
}
