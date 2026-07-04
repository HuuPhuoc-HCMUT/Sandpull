import Foundation

protocol CalendarProvider {
    /// Return all events whose start date falls within [now, now + horizon].
    func eventsStartingNow(within horizon: TimeInterval) -> [CalendarEvent]
}
