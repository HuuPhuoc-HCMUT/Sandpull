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

    // MARK: - Schedule system notification (fires even if app is killed)

    func schedule(for item: TimerItem) {
        let content = UNMutableNotificationContent()
        content.title = item.title.isEmpty ? "Timer Complete" : item.title
        content.body = "\(item.formattedDuration) — time's up!"
        if UserDefaults.standard.notificationSoundEnabled {
            content.sound = .default
        }
        // .timeSensitive bypasses Focus Mode but needs entitlement with real signing.
        // Use .active for ad-hoc builds — still fires, just won't break Focus.
        content.interruptionLevel = .active

        let interval = max(1, item.remaining)
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
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner when app is foreground; sound is controlled above via NSSound
        handler([.banner, .badge])
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
