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
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let decoded = try? JSONDecoder().decode([TimerItem].self, from: data) else { return }
        items = decoded
        for index in items.indices {
            if items[index].isExpired {
                // App was away when this fired — keep the task, don't popup again
                items[index].didNotify = true
            } else {
                NotificationManager.shared.schedule(for: items[index])
            }
        }
        persist()
    }
}
