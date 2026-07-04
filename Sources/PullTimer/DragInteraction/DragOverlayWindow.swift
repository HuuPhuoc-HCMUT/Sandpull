import AppKit

@MainActor
final class DragOverlayWindow: NSWindow {
    let overlayView = DragOverlayView()

    init() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        super.init(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        // .statusBar + 1 to capture mouse events above the menu bar (statusBar = 25)
        level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        // Window is visual-only; mouse events are handled by StatusBarController's monitors
        ignoresMouseEvents = true
        acceptsMouseMovedEvents = false
        isReleasedWhenClosed = false

        overlayView.frame = contentView!.bounds
        overlayView.autoresizingMask = [.width, .height]
        contentView?.addSubview(overlayView)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func show(iconScreenPoint: NSPoint) {
        // Resize to current main screen (handles display config changes)
        if let screen = NSScreen.main {
            setFrame(screen.frame, display: false)
            overlayView.frame = contentView!.bounds
        }
        // Convert icon's screen coordinate to window coordinate
        let windowOrigin = convertFromScreen(NSRect(origin: iconScreenPoint, size: .zero)).origin
        overlayView.originPoint = windowOrigin
        orderFront(nil)  // visual only — don't steal key focus
    }

    func hide() {
        orderOut(nil)
    }
}
