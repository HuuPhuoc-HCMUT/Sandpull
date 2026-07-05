import EventKit
import Foundation

/// Reads events from Calendar.app via EventKit.
/// Works with all calendar sources already synced into Apple Calendar:
/// iCloud, Google, Microsoft 365, Exchange, local.
///
/// Threading model:
///   - prefetch() runs async (off main thread via Task)
///   - When done, it deposits results into calendarCache on @MainActor
///   - The drag loop reads calendarCache synchronously, zero latency
@MainActor
final class AppleCalendarProvider: CalendarProvider {
    static let shared = AppleCalendarProvider()

    private let store = EKEventStore()

    // Written by prefetch(), read synchronously by the drag loop — both on @MainActor
    private(set) var calendarCache: [CalendarEvent] = []

    private init() {}

    // MARK: - Authorization

    var isAuthorized: Bool {
        let s = EKEventStore.authorizationStatus(for: .event)
        if #available(macOS 14.0, *) { return s == .fullAccess }
        return s == .authorized
    }

    func requestAccess() async -> Bool {
        if isAuthorized { return true }
        if #available(macOS 14.0, *) {
            return (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            return await withCheckedContinuation { cont in
                store.requestAccess(to: .event) { granted, _ in
                    cont.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Cache

    /// Fetch events from EventKit and store in calendarCache.
    /// Call once before a drag session begins — never blocks the drag loop.
    func prefetch(horizon: TimeInterval = 24 * 3600) async {
        guard isAuthorized else { return }
        let now = Date()
        let end = now.addingTimeInterval(horizon)
        let predicate = store.predicateForEvents(withStart: now, end: end, calendars: nil)
        // EKEventStore.events(matching:) can block briefly — run off main actor
        let raw: [EKEvent] = await Task.detached(priority: .userInitiated) { [store] in
            store.events(matching: predicate)
        }.value
        calendarCache = raw.compactMap { ek -> CalendarEvent? in
            guard let start = ek.startDate, let end = ek.endDate,
                  !ek.isAllDay else { return nil }
            return CalendarEvent(
                id: UUID(),
                title: ek.title ?? "Event",
                startDate: start,
                endDate: end
            )
        }
        .sorted { $0.startDate < $1.startDate }
    }

    func clearCache() {
        calendarCache = []
    }

    // MARK: - CalendarProvider

    /// Synchronous — reads only the in-memory cache. Zero I/O, zero latency.
    func eventsStartingNow(within horizon: TimeInterval) -> [CalendarEvent] {
        let cutoff = Date().addingTimeInterval(horizon)
        return calendarCache.filter { $0.startDate <= cutoff }
    }
}
