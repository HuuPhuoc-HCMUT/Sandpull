import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock and CMD-Tab
        NSApp.setActivationPolicy(.accessory)

        // Wire up subsystems
        NotificationManager.shared.requestAuthorization()

        Task { @MainActor in
            let store = TimerStore.shared
            statusBarController = StatusBarController(store: store)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false  // Stay alive as menu bar app
    }
}
