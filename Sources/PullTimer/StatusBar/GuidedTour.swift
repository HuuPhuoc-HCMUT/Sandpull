import AppKit
import SwiftUI

extension Notification.Name {
    static let startGuidedTour = Notification.Name("com.pulltimer.startGuidedTour")
}

@MainActor
final class GuidedTour {
    private var dimWindows: [TourDimWindow] = []
    private var stepWindow: TourStepWindow?
    private var escapeMonitor: Any?
    private var cancelled = false
    private var running = false

    var isRunning: Bool { running }

    private let totalSteps = 4
    private let iconFrame: () -> NSRect
    private let closeChrome: () -> Void
    private let fallbackDrag: (NSPoint, NSPoint) async -> TimeInterval
    private let openSave: (TimeInterval) -> Void
    private let onFinish: () -> Void

    init(
        iconFrame: @escaping () -> NSRect,
        closeChrome: @escaping () -> Void,
        fallbackDrag: @escaping (NSPoint, NSPoint) async -> TimeInterval,
        openSave: @escaping (TimeInterval) -> Void,
        onFinish: @escaping () -> Void = {}
    ) {
        self.iconFrame = iconFrame
        self.closeChrome = closeChrome
        self.fallbackDrag = fallbackDrag
        self.openSave = openSave
        self.onFinish = onFinish
    }

    func start() {
        guard !running else { return }
        running = true
        cancelled = false
        closeChrome()
        NSApp.activate(ignoringOtherApps: true)

        showDim()
        showStep(1, "Watch the hourglass in the menu bar.")
        listenForEscape()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { [weak self] in
            guard let self, !self.cancelled else { return }
            Task { await self.runDemo() }
        }
    }

    func cancel() {
        guard running else { return }
        cancelled = true
        finish()
    }

    private func runDemo() async {
        guard !cancelled else { return }
        showStep(2, "Drag down to choose a time.\nQuarter-hours click.")
        let icon = iconCenter()
        let mid = NSPoint(x: icon.x, y: icon.y - 390)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        guard !cancelled else { return }
        let duration = await fallbackDrag(icon, mid)
        guard !cancelled else { return }

        showStep(3, "Release — this window opens\nto name the timer.")
        openSave(max(60, duration))
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        guard !cancelled else { return }

        showStep(4, "Type a name and Save.\nThis creates a real timer.")
    }

    func didFinishSave() {
        guard running, !cancelled else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            self?.finish()
        }
    }

    private func showDim() {
        guard dimWindows.isEmpty else { return }
        dimWindows = NSScreen.screens.map { TourDimWindow(screen: $0) }
        for window in dimWindows {
            window.orderFront(nil)
        }
    }

    private func showStep(_ number: Int, _ text: String) {
        if stepWindow == nil {
            let window = TourStepWindow(total: totalSteps, onSkip: { [weak self] in self?.cancel() })
            stepWindow = window
            window.orderFront(nil)
        }
        stepWindow?.set(step: number, text: text)
    }

    private func listenForEscape() {
        if let m = escapeMonitor { NSEvent.removeMonitor(m) }
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.cancel()
                return nil
            }
            return event
        }
    }

    private func finish() {
        running = false
        cancelled = true
        if let m = escapeMonitor { NSEvent.removeMonitor(m); escapeMonitor = nil }
        stepWindow?.orderOut(nil)
        stepWindow = nil
        dimWindows.forEach { $0.orderOut(nil) }
        dimWindows.removeAll()
        onFinish()
    }

    private func iconCenter() -> NSPoint {
        let r = iconFrame()
        return NSPoint(x: r.midX, y: r.midY)
    }
}

// MARK: - Soft wash

@MainActor
final class TourDimWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        isReleasedWhenClosed = false
        backgroundColor = NSColor.black.withAlphaComponent(0.38)
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue - 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        alphaValue = 0
        animator().alphaValue = 1
    }

    override var canBecomeKey: Bool { false }
}

// MARK: - Large step card

@MainActor
final class TourStepWindow: NSWindow {
    private let host: NSHostingController<TourStepView>
    private let total: Int
    private let onSkip: () -> Void

    init(total: Int, onSkip: @escaping () -> Void) {
        self.total = total
        self.onSkip = onSkip
        let host = NSHostingController(
            rootView: TourStepView(step: 1, total: total, text: "", onSkip: onSkip)
        )
        self.host = host
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 572, height: 416),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        isReleasedWhenClosed = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 4)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        contentViewController = host
    }

    func set(step: Int, text: String) {
        host.rootView = TourStepView(step: step, total: total, text: text, onSkip: onSkip)
        setContentSize(NSSize(width: 572, height: 416))
        pinLeftCenter()
    }

    private func pinLeftCenter() {
        guard let screen = NSScreen.main else { return }
        let vis = screen.visibleFrame
        let leftMidX = vis.minX + vis.width * 0.22
        let centerY = vis.minY + vis.height * 0.55
        setFrameOrigin(NSPoint(
            x: leftMidX - frame.width / 2,
            y: centerY - frame.height / 2
        ))
    }

    override var canBecomeKey: Bool { false }
}

struct TourStepView: View {
    let step: Int
    let total: Int
    let text: String
    var onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 21) {
            HStack(alignment: .firstTextBaseline, spacing: 13) {
                Text("\(step)")
                    .font(.system(size: 187, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .frame(width: 143, alignment: .leading)
                Text("/ \(total)")
                    .font(.system(size: 49, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.75))
            }
            Text(text)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.leading)
                .frame(width: 494, height: 94, alignment: .topLeading)
            Button("Skip") { onSkip() }
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.9))
                .buttonStyle(.plain)
                .hoverable()
        }
        .frame(width: 546, height: 390, alignment: .topLeading)
        .padding(13)
    }
}
