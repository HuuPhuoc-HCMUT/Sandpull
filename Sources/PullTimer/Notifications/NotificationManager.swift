import UserNotifications
import Foundation
import AppKit

final class NotificationManager: NSObject, @unchecked Sendable {
    static let shared = NotificationManager()

    private let lock = NSLock()
    private var pendingOpenList = false

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// True if a notification tap arrived before the menu bar was ready.
    func consumePendingOpenList() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let pending = pendingOpenList
        pendingOpenList = false
        return pending
    }

    func requestOpenTimerList() {
        lock.lock()
        pendingOpenList = true
        lock.unlock()
        NotificationCenter.default.post(name: .openTimerList, object: nil)
    }

    // MARK: - Authorization

    func requestAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .sound, .badge]
                ) { _, _ in }
            default:
                break
            }
        }
    }

    /// Wipe banners left in Notification Center from earlier runs.
    func clearDelivered() {
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        center.setBadgeCount(0)
    }

    // MARK: - Schedule system notification (backup if the app is killed)
    //
    // Accessory / menu-bar apps are usually not "foreground", so willPresent
    // never runs and a trigger at endAt would show a system banner next to
    // our in-app popup. Fire a few seconds later; while we are alive, tick()
    // cancels this request first.

    private static let backupDelay: TimeInterval = 3

    func schedule(for item: TimerItem) {
        let content = UNMutableNotificationContent()
        content.title = item.title.isEmpty ? "Timer Complete" : item.title
        content.body = "\(item.formattedDuration) — time's up!"
        if UserDefaults.standard.notificationSoundEnabled {
            content.sound = .default
        }
        content.interruptionLevel = .active

        let interval = max(1, item.remaining + Self.backupDelay)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: item.notificationID,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[PullTimer] schedule failed: \(error)")
            }
        }
    }

    // MARK: - In-process expiry (called by TimerStore.tick when app is alive)
    //
    // This fires 100% of the time regardless of notification permissions or
    // Focus Mode, because it runs directly inside the running app process.

    func fireExpiry(for _: TimerItem) {
        // Sound only — the in-app expiry popup is shown by StatusBarController.
        // Scheduled UN notifications remain as backup when the app is not running.
        if UserDefaults.standard.notificationSoundEnabled {
            NSSound(named: "Glass")?.play()
        }
    }

    // MARK: - Cancel

    func cancel(id: UUID) {
        let ids = [id.uuidString, "expiry-\(id.uuidString)"]
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: ids)
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // App is alive — swallow the system banner. Also drop it from
        // Notification Center in case delivery already happened.
        let id = notification.request.identifier
        center.removeDeliveredNotifications(withIdentifiers: [id])
        handler([])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler handler: @escaping () -> Void
    ) {
        requestOpenTimerList()
        Task { @MainActor in
            NSApp.activate(ignoringOtherApps: true)
        }
        handler()
    }
}
