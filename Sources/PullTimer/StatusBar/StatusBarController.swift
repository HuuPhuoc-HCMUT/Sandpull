import AppKit
import SwiftUI
import Combine

@MainActor
final class StatusBarController: NSObject {
    private let store: TimerStore
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let overlayWindow: DragOverlayWindow

    private var saveWindow: FloatingWindow?
    private var settingsWindow: FloatingWindow?
    private var cancellables = Set<AnyCancellable>()
    private weak var statusButton: NSStatusBarButton?
    private var popoverCloseMonitor: Any?   // global monitor to dismiss on outside click
    private var isPopoverOpen = false       // intent flag — not animation state

    init(store: TimerStore) {
        self.store = store
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        self.overlayWindow = DragOverlayWindow()
        super.init()

        setupButton()
        setupPopover()
        observeStore()
        observeTimerExpiry()
    }

    // MARK: - Setup

    private func setupButton() {
        guard let button = statusItem.button else { return }
        statusButton = button
        button.image = makeMenuBarIcon()
        button.imageScaling = .scaleProportionallyDown
        button.action = #selector(buttonAction(_:))
        button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        button.target = self
    }

    private func setupPopover() {
        let listView = TimerListView(store: store)
        // Use .applicationDefined so we control dismiss manually via global monitor
        popover.contentViewController = NSHostingController(rootView: listView)
        popover.behavior = .applicationDefined
        popover.animates = true
    }

    private func observeStore() {
        // Only need to react when items are added/removed (not every tick)
        store.$items
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshIcon() }
            .store(in: &cancellables)
    }

    private func observeTimerExpiry() {
        NotificationCenter.default.addObserver(
            forName: .timerExpired, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.flashBadge() }
        }
    }

    // MARK: - Button Action

    @objc private func buttonAction(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        switch event.type {
        case .rightMouseDown:
            NSMenu.popUpContextMenu(makeContextMenu(), with: event, for: sender)

        case .leftMouseDown:
            // Close any stale save window immediately
            saveWindow?.close()
            saveWindow = nil

            // Snapshot intent before entering the tracking loop
            let wasOpen = isPopoverOpen
            if wasOpen { closePopover() }

            // Capture icon screen position before entering the tracking loop
            guard let buttonWindow = sender.window else { return }
            let boundsInWindow = sender.convert(sender.bounds, to: nil)
            let screenFrame = buttonWindow.convertToScreen(boundsInWindow)
            let iconBottom = NSPoint(x: screenFrame.midX, y: screenFrame.minY)

            trackDrag(from: iconBottom, wasPopoverOpen: wasOpen)

        default:
            break
        }
    }

    // MARK: - Synchronous Drag Tracking Loop
    //
    // Using NSApp.nextEvent in .eventTracking mode is the correct AppKit
    // approach for status bar drag interactions. It bypasses the button's
    // own tracking loop that would otherwise swallow drag events.

    private func trackDrag(from iconScreenPoint: NSPoint, wasPopoverOpen: Bool) {
        var isDragging = false
        let screenHeight = NSScreen.main?.frame.height ?? 900

        while true {
            guard let event = NSApp.nextEvent(
                matching: [.leftMouseDragged, .leftMouseUp, .keyDown],
                until: .distantFuture,
                inMode: .eventTracking,
                dequeue: true
            ) else { continue }

            switch event.type {
            case .leftMouseDragged:
                let current = NSEvent.mouseLocation
                let dx = current.x - iconScreenPoint.x
                let dy = current.y - iconScreenPoint.y
                let dist = sqrt(dx * dx + dy * dy)

                if !isDragging {
                    guard dist > 6 else { continue }
                    isDragging = true
                    overlayWindow.show(iconScreenPoint: iconScreenPoint)
                }

                // Pass both origin and current point in window coordinates
                let originWin = overlayWindow.convertFromScreen(
                    NSRect(origin: iconScreenPoint, size: .zero)
                ).origin
                let currentWin = overlayWindow.convertFromScreen(
                    NSRect(origin: current, size: .zero)
                ).origin
                overlayWindow.overlayView.updateDrag(
                    from: originWin,
                    to: currentWin,
                    screenHeight: screenHeight
                )

            case .leftMouseUp:
                let finalDistance = overlayWindow.overlayView.dragDistance
                overlayWindow.overlayView.resetDrag()
                overlayWindow.hide()

                if isDragging && !DurationMapper.isInDeadZone(finalDistance) {
                    let duration = DurationMapper.toDuration(
                        pixels: finalDistance,
                        screenHeight: screenHeight
                    )
                    let releaseScreen = NSEvent.mouseLocation
                    showSaveWindow(duration: duration, near: releaseScreen)
                } else if !isDragging && !wasPopoverOpen {
                    // Simple click with popover closed → open it
                    if let button = statusButton { openPopover(button) }
                }
                // !isDragging && wasPopoverOpen → already closed above, nothing to do
                return

            case .keyDown where event.keyCode == 53: // Escape
                overlayWindow.overlayView.resetDrag()
                overlayWindow.hide()
                return

            default:
                break
            }
        }
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()

        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "Quit PullTimer",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quit.target = NSApp
        menu.addItem(quit)
        return menu
    }

    @objc private func openSettings() {
        settingsWindow?.close()
        settingsWindow = nil
        let view = SettingsView(onClose: { [weak self] in
            self?.settingsWindow?.close()
            self?.settingsWindow = nil
        })
        let window = FloatingWindow(view: view)
        settingsWindow = window
        // Center below menu bar
        if let screen = NSScreen.main {
            let x = screen.frame.midX
            let y = screen.visibleFrame.maxY - 20
            window.showAt(releasePoint: NSPoint(x: x, y: y))
        } else {
            window.showAt(releasePoint: .zero)
        }
    }

    // MARK: - Popover

    private func openPopover(_ sender: NSStatusBarButton) {
        isPopoverOpen = true
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        startPopoverCloseMonitor()
    }

    private func closePopover() {
        isPopoverOpen = false
        popover.performClose(nil)
        if let m = popoverCloseMonitor { NSEvent.removeMonitor(m); popoverCloseMonitor = nil }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if isPopoverOpen {
            closePopover()
        } else {
            openPopover(sender)
        }
    }

    private func startPopoverCloseMonitor() {
        popoverCloseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.closePopover()
            }
        }
    }

    // MARK: - Icon (static — no countdown in menu bar)

    private func refreshIcon() {
        guard let button = statusItem.button else { return }
        button.image = makeMenuBarIcon()
        button.title = ""
    }

    private func makeMenuBarIcon() -> NSImage {
        // Show a dot badge when timers are active so user knows something is running
        if store.items.isEmpty {
            let img = NSImage(systemSymbolName: "timer", accessibilityDescription: "PullTimer") ?? NSImage()
            img.isTemplate = true
            return img
        } else {
            // Filled timer icon to indicate active timers
            let cfg = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            let img = NSImage(systemSymbolName: "timer", variableValue: 1.0, accessibilityDescription: "PullTimer")?
                .withSymbolConfiguration(cfg) ?? NSImage()
            img.isTemplate = true
            return img
        }
    }

    private func flashBadge() {
        // Brief visual pulse — no-op since icon is now static
    }

    // MARK: - Save Window

    private func showSaveWindow(duration: TimeInterval, near point: NSPoint?) {
        saveWindow?.close()
        saveWindow = nil

        let view = SaveTimerView(duration: duration) { [weak self] title, dur in
            guard let self else { return }
            self.store.add(TimerItem(title: title, duration: dur))
            self.saveWindow?.close()
            self.saveWindow = nil
        } onCancel: { [weak self] in
            self?.saveWindow?.close()
            self?.saveWindow = nil
        }
        let window = FloatingWindow(view: view)
        saveWindow = window
        window.showAt(releasePoint: point ?? NSPoint(
            x: NSScreen.main.map { $0.frame.midX } ?? 400,
            y: NSScreen.main.map { $0.frame.midY } ?? 300
        ))
    }
}
