import EventKit
import Foundation

actor RemindersManager {
    static let shared = RemindersManager()
    private let store = EKEventStore()

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "remindersEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "remindersEnabled") }
    }

    private init() {}

    // Returns true only if the system actually grants access
    func requestAccess() async -> Bool {
        if #available(macOS 14.0, *) {
            do {
                return try await store.requestFullAccessToReminders()
            } catch {
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                store.requestAccess(to: .reminder) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // Check current authorization without prompting
    func checkAccess() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if #available(macOS 14.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized
        }
    }

    func addReminder(for item: TimerItem) async throws -> String {
        let reminder = EKReminder(eventStore: store)
        reminder.title = item.title.isEmpty ? "PullTimer" : item.title

        // defaultCalendarForNewReminders() can be nil if iCloud Reminders not set up
        guard let calendar = store.defaultCalendarForNewReminders() else {
            throw RemindersError.noDefaultCalendar
        }
        reminder.calendar = calendar
        reminder.addAlarm(EKAlarm(absoluteDate: item.endAt))
        reminder.dueDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: item.endAt
        )
        try store.save(reminder, commit: true)
        return reminder.calendarItemIdentifier
    }

    func removeReminder(id: String) async throws {
        guard let item = store.calendarItem(withIdentifier: id),
              let reminder = item as? EKReminder else { return }
        try store.remove(reminder, commit: true)
    }
}

enum RemindersError: LocalizedError {
    case noDefaultCalendar
    var errorDescription: String? {
        "No default Reminders calendar. Please set one up in the Reminders app."
    }
}
