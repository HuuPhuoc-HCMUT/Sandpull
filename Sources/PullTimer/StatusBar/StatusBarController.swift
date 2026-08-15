import AppKit
import SwiftUI
import Combine

@MainActor
final class StatusBarController: NSObject {
    private let store: TimerStore
    private let statusItem: NSStatusItem
    private let overlayWindow: DragOverlayWindow

    private var listWindow: FloatingWindow?
    private var saveWindow: FloatingWindow?
    private var settingsWindow: FloatingWindow?
    private var expiryWindow: FloatingWindow?
    private var cancellables = Set<AnyCancellable>()
    private weak var statusButton: NSStatusBarButton?
    private var popoverCloseMonitor: Any?   // global monitor to dismiss on outside click
    private var isPopoverOpen = false       // intent flag — not animation state
    private var tour: GuidedTour?

    init(store: TimerStore) {
        self.store = store
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.overlayWindow = DragOverlayWindow()
        super.init()

        setupButton()
        observeStore()
        observeTimerExpiry()
        observeOpenTimerList()
        observeGuidedTour()
        if NotificationManager.shared.consumePendingOpenList() {
            DispatchQueue.main.async { [weak self] in
                self?.showTimerList()
            }
        }
    }

    // MARK: - Setup

    private func setupButton() {
        guard let button = statusItem.button else { return }
        statusButton = button
        button.image = MenuBarIcon.image(progress: 0)
        button.imageScaling = .scaleProportionallyDown
        button.imagePosition = .imageLeft
        button.action = #selector(buttonAction(_:))
        button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        button.target = self
        refreshIcon()
    }

    private func observeStore() {
        store.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshIcon() }
            .store(in: &cancellables)

        AppSettings.shared.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshIcon() }
            .store(in: &cancellables)
    }

    private func observeTimerExpiry() {
        NotificationCenter.default.addObserver(
            forName: .timerExpired, object: nil, queue: .main
        ) { [weak self] notification in
            let item = notification.object as? TimerItem
            Task { @MainActor [weak self] in
                guard let self, let item else { return }
                self.showExpiryPopup(for: item)
            }
        }
    }

    private func observeGuidedTour() {
        NotificationCenter.default.addObserver(
            forName: .startGuidedTour, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.startGuidedTour()
            }
        }
    }

    private func observeOpenTimerList() {
        NotificationCenter.default.addObserver(
            forName: .openTimerList, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.showTimerList()
            }
        }
    }

    // MARK: - Button Action

    @objc private func buttonAction(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        switch event.type {
        case .rightMouseDown:
            NSMenu.popUpContextMenu(makeContextMenu(), with: event, for: sender)

        case .leftMouseDown:
            NSApp.activate(ignoringOtherApps: true)

            // Close any stale floating windows immediately
            saveWindow?.close()
            saveWindow = nil
            expiryWindow?.close()
            expiryWindow = nil

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
        var wasInCancelZone = false
        var lastClockSlot: Int?
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

                let inCancel = overlayWindow.overlayView.isInCancelZone
                if inCancel && !wasInCancelZone && AppSettings.shared.hapticOnCancel {
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                }
                wasInCancelZone = inCancel

                if !inCancel && !DurationMapper.isInDeadZone(dist) {
                    let duration = DurationMapper.toDuration(pixels: dist, screenHeight: screenHeight)
                    if let slot = DurationMapper.clockQuarterSlot(for: duration), slot != lastClockSlot {
                        Self.playClockHaptic()
                        lastClockSlot = slot
                    }
                } else if DurationMapper.isInDeadZone(dist) {
                    lastClockSlot = nil
                }

            case .leftMouseUp:
                let inCancelZone = overlayWindow.overlayView.isInCancelZone
                let finalDistance = overlayWindow.overlayView.dragDistance
                overlayWindow.overlayView.resetDrag()
                overlayWindow.hide()

                if inCancelZone {
                    // User dragged into cancel zone — discard silently
                } else if isDragging && !DurationMapper.isInDeadZone(finalDistance) {
                    let duration = DurationMapper.toDuration(
                        pixels: finalDistance,
                        screenHeight: screenHeight
                    )
                    closePopover()
                    showSaveWindow(duration: duration, title: "", near: menuBarPoint()) { [weak self] title, dur in
                        self?.store.add(TimerItem(title: title, duration: dur))
                    }
                } else if !isDragging && !wasPopoverOpen {
                    if let button = statusButton { openPopover(button) }
                }
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

    /// Two pulses — levelChange then generic — so a clock notch reads stronger than cancel.
    private static func playClockHaptic() {
        let performer = NSHapticFeedbackManager.defaultPerformer
        performer.perform(.levelChange, performanceTime: .now)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            performer.perform(.generic, performanceTime: .now)
        }
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()

        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let help = NSMenuItem(title: "How it works…", action: #selector(startGuidedTour), keyEquivalent: "?")
        help.target = self
        menu.addItem(help)

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
        }, onHelp: { [weak self] in
            self?.settingsWindow?.close()
            self?.settingsWindow = nil
            self?.startGuidedTour()
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
        listWindow?.close()
        listWindow = nil

        let listView = TimerListView(store: store, onEdit: { [weak self] item in
            self?.editTimer(item)
        }, onHelp: { [weak self] in
            self?.startGuidedTour()
        })
        let window = FloatingWindow(view: listView)
        listWindow = window

        let bounds = sender.convert(sender.bounds, to: nil)
        let screen = sender.window?.convertToScreen(bounds) ?? .zero
        window.showBelow(NSPoint(x: screen.midX, y: screen.minY))
        startPopoverCloseMonitor()
    }

    private func closePopover() {
        isPopoverOpen = false
        listWindow?.close()
        listWindow = nil
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

    // MARK: - Icon + countdown + hover tooltip

    private func refreshIcon() {
        guard let button = statusItem.button else { return }

        if let item = store.soonestActive {
            button.image = MenuBarIcon.image(progress: CGFloat(item.elapsedProgress))
            if AppSettings.shared.showMenuBarCountdown {
                button.imagePosition = .imageLeft
                button.attributedTitle = Self.menuBarTitle(item.formattedMenuBar)
            } else {
                button.imagePosition = .imageOnly
                button.attributedTitle = NSAttributedString(string: "")
                button.title = ""
            }
        } else if !store.doneItems.isEmpty {
            button.image = MenuBarIcon.image(progress: 1)
            button.imagePosition = .imageOnly
            button.attributedTitle = NSAttributedString(string: "")
            button.title = ""
        } else {
            button.image = MenuBarIcon.image(progress: 0)
            button.imagePosition = .imageOnly
            button.attributedTitle = NSAttributedString(string: "")
            button.title = ""
        }
        button.toolTip = hoverTooltip()
    }

    private static func menuBarTitle(_ text: String) -> NSAttributedString {
        NSAttributedString(string: " \(text)", attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        ])
    }

    private func hoverTooltip() -> String {
        let active = store.activeItems
        let done = store.doneItems
        if active.isEmpty && done.isEmpty {
            return "Drag down to create a timer"
        }
        var lines = active.map { "\($0.displayTitle) · \($0.formattedRemaining) left" }
        if !done.isEmpty {
            lines.append(done.count == 1 ? "1 done" : "\(done.count) done")
        }
        return lines.joined(separator: "\n")
    }

    func showTimerList() {
        expiryWindow?.close()
        expiryWindow = nil
        saveWindow?.close()
        saveWindow = nil
        guard let button = statusButton else { return }
        if !isPopoverOpen {
            openPopover(button)
        }
    }

    // MARK: - Expiry Popup

    private func showExpiryPopup(for item: TimerItem) {
        expiryWindow?.close()
        expiryWindow = nil

        let view = ExpiryPopupView(item: item) { [weak self] in
            self?.showTimerList()
        } onDismiss: { [weak self] in
            self?.expiryWindow?.close()
            self?.expiryWindow = nil
        } onSnooze: { [weak self] minutes in
            self?.store.snooze(id: item.id, minutes: minutes)
            self?.expiryWindow?.close()
            self?.expiryWindow = nil
        }
        NotificationManager.shared.cancel(id: item.id)
        let window = FloatingWindow(view: view)
        expiryWindow = window
        if let point = menuBarPoint() {
            window.showBelow(point)
        } else if let screen = NSScreen.main {
            window.showBelow(NSPoint(x: screen.frame.midX, y: screen.visibleFrame.maxY - 8))
        } else {
            window.showAt(releasePoint: .zero)
        }
    }

    // MARK: - Save Window

    private func editTimer(_ item: TimerItem) {
        closePopover()
        let duration = item.isExpired ? max(60, item.duration) : max(60, item.remaining)
        showSaveWindow(duration: duration, title: item.title, near: menuBarPoint()) { [weak self] title, dur in
            self?.store.update(id: item.id, title: title, duration: dur)
        }
    }

    private func menuBarPoint() -> NSPoint? {
        guard let button = statusButton, let window = button.window else { return nil }
        let bounds = button.convert(button.bounds, to: nil)
        let screen = window.convertToScreen(bounds)
        return NSPoint(x: screen.midX, y: screen.minY - 12)
    }

    /// Same anchor the timer list uses — just under the menu bar icon.
    private func menuBarAnchor() -> NSPoint? {
        guard let button = statusButton, let window = button.window else { return nil }
        let bounds = button.convert(button.bounds, to: nil)
        let screen = window.convertToScreen(bounds)
        return NSPoint(x: screen.midX, y: screen.minY)
    }

    private func showSaveWindow(
        duration: TimeInterval,
        title: String,
        near point: NSPoint?,
        tourAutoTitle: String? = nil,
        onSave: @escaping (String, TimeInterval) -> Void
    ) {
        saveWindow?.close()
        saveWindow = nil

        let view = SaveTimerView(
            duration: duration,
            title: title,
            tourAutoTitle: tourAutoTitle
        ) { [weak self] title, dur in
            onSave(title, dur)
            self?.saveWindow?.close()
            self?.saveWindow = nil
        } onCancel: { [weak self] in
            self?.saveWindow?.close()
            self?.saveWindow = nil
        }
        let window = FloatingWindow(view: view)
        saveWindow = window
        if tourAutoTitle != nil {
            window.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 6)
        }
        if let point {
            window.showBelow(point)
        } else {
            window.showAt(releasePoint: NSPoint(
                x: NSScreen.main.map { $0.frame.midX } ?? 400,
                y: NSScreen.main.map { $0.frame.midY } ?? 300
            ))
        }
        if tourAutoTitle != nil {
            window.orderFrontRegardless()
        }
    }

    // MARK: - Guided tour

    @objc func startGuidedTour() {
        if tour?.isRunning == true { return }
        settingsWindow?.close()
        settingsWindow = nil
        saveWindow?.close()
        saveWindow = nil
        expiryWindow?.close()
        expiryWindow = nil
        closePopover()

        let next = GuidedTour(
            iconFrame: { [weak self] in self?.statusIconFrame() ?? .zero },
            closeChrome: { [weak self] in
                self?.settingsWindow?.close()
                self?.settingsWindow = nil
                self?.saveWindow?.close()
                self?.saveWindow = nil
                self?.closePopover()
            },
            fallbackDrag: { [weak self] icon, mid in
                await self?.playFallbackDrag(from: icon, to: mid) ?? 15 * 60
            },
            openSave: { [weak self] duration in
                guard let self else { return }
                self.tour?.revealChrome()
                self.showSaveWindow(
                    duration: duration,
                    title: "",
                    near: self.menuBarAnchor(),
                    tourAutoTitle: "Focus"
                ) { title, dur in
                    self.store.add(TimerItem(title: title, duration: dur))
                    self.tour?.didFinishSave()
                }
            },
            onFinish: { [weak self] in
                self?.saveWindow?.close()
                self?.saveWindow = nil
                self?.listWindow?.level = .floating
            }
        )
        tour = next
        next.start()
    }

    private func statusIconFrame() -> NSRect {
        guard let button = statusButton, let window = button.window else { return .zero }
        return window.convertToScreen(button.convert(button.bounds, to: nil))
    }

    private func playFallbackDrag(from icon: NSPoint, to mid: NSPoint) async -> TimeInterval {
        let previousLevel = overlayWindow.level
        overlayWindow.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 5)
        overlayWindow.show(iconScreenPoint: icon)
        let screenH = NSScreen.main?.frame.height ?? 900
        func win(_ p: NSPoint) -> NSPoint {
            overlayWindow.convertFromScreen(NSRect(origin: p, size: .zero)).origin
        }
        let origin = win(icon)
        let steps = 52
        for i in 1...steps {
            guard tour?.isRunning == true else { break }
            let t = CGFloat(i) / CGFloat(steps)
            let eased = 1 - pow(1 - t, 2)
            let p = NSPoint(x: icon.x + (mid.x - icon.x) * eased, y: icon.y + (mid.y - icon.y) * eased)
            overlayWindow.overlayView.updateDrag(from: origin, to: win(p), screenHeight: screenH)
            try? await Task.sleep(nanoseconds: 62_000_000)
        }
        try? await Task.sleep(nanoseconds: 2_200_000_000)
        let distance = hypot(mid.x - icon.x, mid.y - icon.y)
        let duration = DurationMapper.toDuration(pixels: distance, screenHeight: screenH)
        overlayWindow.overlayView.resetDrag()
        overlayWindow.hide()
        overlayWindow.level = previousLevel
        return duration
    }
}
