import Foundation
import Combine

extension Notification.Name {
    static let timerExpired = Notification.Name("com.pulltimer.timerExpired")
    static let openTimerList = Notification.Name("com.pulltimer.openTimerList")
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
        syncReminder(for: item)
    }

    private func syncReminder(for item: TimerItem) {
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

    var activeItems: [TimerItem] {
        items.filter { !$0.isExpired }.sorted { $0.endAt < $1.endAt }
    }

    var doneItems: [TimerItem] {
        items.filter(\.isExpired)
    }

    var soonestActive: TimerItem? { activeItems.first }

    func update(id: UUID, title: String, duration: TimeInterval) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let old = items[idx]
        let baseline = old.isExpired ? old.duration : old.remaining
        let durationChanged = abs(baseline - duration) > 1

        if !durationChanged && !old.isExpired {
            items[idx].title = title
            persist()
            return
        }

        NotificationManager.shared.cancel(id: id)
        if let reminderID = old.reminderID {
            Task { try? await RemindersManager.shared.removeReminder(id: reminderID) }
        }

        let next = TimerItem(id: old.id, title: title, duration: duration)
        items[idx] = next
        persist()
        NotificationManager.shared.schedule(for: next)
        syncReminder(for: next)
    }

    func snooze(id: UUID, minutes: Int) {
        let title = items.first(where: { $0.id == id })?.title ?? ""
        update(id: id, title: title, duration: TimeInterval(minutes * 60))
    }

    func clearDone() {
        let doneIDs = doneItems.map(\.id)
        for id in doneIDs { remove(id: id) }
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
        var newlyExpired: [TimerItem] = []
        for index in items.indices where items[index].isExpired && !items[index].didNotify {
            items[index].didNotify = true
            newlyExpired.append(items[index])
        }
        if !newlyExpired.isEmpty {
            persist()
            for item in newlyExpired {
                NotificationManager.shared.cancel(id: item.id)
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
        NotificationManager.shared.clearDelivered()
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let decoded = try? JSONDecoder().decode([TimerItem].self, from: data) else { return }
        items = decoded
        for index in items.indices {
            if items[index].isExpired {
                // App was away when this fired — keep the task, don't popup again
                items[index].didNotify = true
                NotificationManager.shared.cancel(id: items[index].id)
            } else {
                NotificationManager.shared.schedule(for: items[index])
            }
        }
        persist()
    }
}
