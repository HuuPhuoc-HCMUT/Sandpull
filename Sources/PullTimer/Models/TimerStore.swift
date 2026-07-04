import Foundation
import Combine

extension Notification.Name {
    static let timerExpired = Notification.Name("com.pulltimer.timerExpired")
}

@MainActor
final class TimerStore: ObservableObject {
    static let shared = TimerStore()

    @Published private(set) var items: [TimerItem] = []
    private var tickTimer: Foundation.Timer?
    private let udKey = "com.pulltimer.timers"

    private init() {
        load()
        startTick()
    }

    // MARK: - Public API

    func add(_ item: TimerItem) {
        items.append(item)
        persist()
        NotificationManager.shared.schedule(for: item)
        Task {
            guard await RemindersManager.shared.isEnabled else { return }
            do {
                let reminderID = try await RemindersManager.shared.addReminder(for: item)
                if let idx = items.firstIndex(where: { $0.id == item.id }) {
                    items[idx].reminderID = reminderID
                    persist()
                }
            } catch {
                // Reminders sync failure is non-fatal
            }
        }
    }

    func remove(id: UUID) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        items.removeAll { $0.id == id }
        persist()
        NotificationManager.shared.cancel(id: id)
        if let reminderID = item.reminderID {
            Task {
                try? await RemindersManager.shared.removeReminder(id: reminderID)
            }
        }
    }

    // MARK: - Tick

    private func startTick() {
        let t = Foundation.Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        tickTimer = t
    }

    private func tick() {
        var expired: [TimerItem] = []
        for item in items where item.isExpired {
            expired.append(item)
        }
        if !expired.isEmpty {
            items.removeAll { $0.isExpired }
            persist()
            for item in expired {
                // Cancel the system notification (we'll handle it in-process)
                NotificationManager.shared.cancel(id: item.id)
                // Fire both: in-process alert + system notification fallback
                NotificationManager.shared.fireExpiry(for: item)
                NotificationCenter.default.post(name: .timerExpired, object: item)
            }
        }
        objectWillChange.send()
    }

    // MARK: - Persistence

    private func persist() {
        let data = try? JSONEncoder().encode(items)
        UserDefaults.standard.set(data, forKey: udKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let decoded = try? JSONDecoder().decode([TimerItem].self, from: data) else { return }
        let now = Date()
        items = decoded.filter { $0.endAt > now }
        // Reschedule notifications for surviving timers — they are lost if app was killed
        for item in items {
            NotificationManager.shared.schedule(for: item)
        }
    }
}
