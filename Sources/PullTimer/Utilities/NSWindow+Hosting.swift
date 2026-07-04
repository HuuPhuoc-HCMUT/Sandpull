import AppKit
import SwiftUI

@MainActor
final class FloatingWindow: NSWindow {
    init<Content: View>(view: Content) {
        super.init(
            contentRect: NSRect(origin: .zero, size: CGSize(width: 300, height: 10)),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isReleasedWhenClosed = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        isMovableByWindowBackground = true
        level = .floating

        let hosting = NSHostingController(rootView: view)
        hosting.sizingOptions = [.preferredContentSize]
        contentViewController = hosting
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // Center of window lands at releasePoint
    func showAt(releasePoint: NSPoint) {
        contentView?.wantsLayer = true
        contentView?.layer?.cornerRadius = 13
        contentView?.layer?.masksToBounds = true

        if let sz = contentViewController?.preferredContentSize, sz.height > 10 {
            setContentSize(sz)
        }

        var origin = NSPoint(
            x: releasePoint.x - frame.width / 2,
            y: releasePoint.y - frame.height / 2
        )
        if let screen = NSScreen.main {
            let vis = screen.visibleFrame
            origin.x = min(max(origin.x, vis.minX + 8), vis.maxX - frame.width - 8)
            origin.y = min(max(origin.y, vis.minY + 8), vis.maxY - frame.height - 8)
        }
        setFrameOrigin(origin)

        alphaValue = 0
        contentView?.layer?.setAffineTransform(CGAffineTransform(scaleX: 0.82, y: 0.82))
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.13
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
        })

        let spring = CASpringAnimation(keyPath: "transform")
        spring.fromValue = CATransform3DMakeScale(0.82, 0.82, 1)
        spring.toValue   = CATransform3DIdentity
        spring.mass = 0.6
        spring.stiffness = 280
        spring.damping = 16
        spring.initialVelocity = 8
        spring.duration = spring.settlingDuration
        spring.isRemovedOnCompletion = true
        contentView?.layer?.add(spring, forKey: "springIn")
        contentView?.layer?.setAffineTransform(.identity)
    }
}
