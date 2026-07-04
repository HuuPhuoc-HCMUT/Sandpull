import Foundation

struct TimelineMapper {
    /// Convert calendar events into render-ready markers for the current drag state.
    /// - Parameters:
    ///   - events: All candidate events from the provider.
    ///   - dragDuration: Current selected duration (from DurationMapper.toDuration).
    ///   - now: Reference time (injectable for testing; defaults to Date()).
    static func markers(
        events: [CalendarEvent],
        dragDuration: TimeInterval,
        now: Date = Date()
    ) -> [TimelineMarker] {
        guard dragDuration > 0 else { return [] }
        let endTime = now.addingTimeInterval(dragDuration)

        return events
            .filter { $0.startDate < endTime }
            .map { event in
                let offset = event.startDate.timeIntervalSince(now)
                let position = CGFloat(offset / dragDuration)
                // Warning: timer end time lands inside the event window
                let isWarning = endTime > event.startDate && endTime < event.endDate
                return TimelineMarker(
                    title: event.title,
                    time: TimeFormatter.endTime(event.startDate),
                    position: min(1.0, max(0.0, position)),
                    isWarning: isWarning
                )
            }
            .sorted { $0.position < $1.position }
    }
}
