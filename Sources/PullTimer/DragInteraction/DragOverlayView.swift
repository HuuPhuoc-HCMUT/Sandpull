import AppKit

@MainActor
final class DragOverlayView: NSView {
    var originPoint: NSPoint = .zero
    private(set) var dragDistance: CGFloat = 0
    private var currentPoint: NSPoint = .zero
    private var screenHeight: CGFloat = 900

    // MARK: - API

    func updateDrag(from origin: NSPoint, to current: NSPoint, screenHeight: CGFloat) {
        self.originPoint = origin
        self.currentPoint = current
        self.screenHeight = screenHeight

        let dx = current.x - origin.x
        let dy = current.y - origin.y
        dragDistance = sqrt(dx * dx + dy * dy)
        needsDisplay = true
    }

    func resetDrag() {
        dragDistance = 0
        needsDisplay = true
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard dragDistance > 4 else { return }

        let inDeadZone = DurationMapper.isInDeadZone(dragDistance)
        drawLine(faded: inDeadZone)
        drawEndDot(faded: inDeadZone)
        if !inDeadZone {
            drawBubble()
        }
    }

    private var dragEndPoint: NSPoint { currentPoint }

    private func drawLine(faded: Bool) {
        let path = NSBezierPath()
        path.move(to: originPoint)
        path.line(to: dragEndPoint)
        path.lineCapStyle = .round

        let alpha: CGFloat = faded ? 0.35 : 0.9
        NSColor.systemPurple.withAlphaComponent(alpha * 0.25).setStroke()
        path.lineWidth = 5
        path.stroke()
        NSColor.systemPurple.withAlphaComponent(alpha).setStroke()
        path.lineWidth = 2
        path.stroke()
    }

    private func drawEndDot(faded: Bool) {
        let c = dragEndPoint
        let r: CGFloat = faded ? 5 : 7
        let rect = NSRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
        let dot = NSBezierPath(ovalIn: rect)
        let alpha: CGFloat = faded ? 0.35 : 1.0
        NSColor.systemPurple.withAlphaComponent(alpha).setFill()
        dot.fill()
        NSColor.white.withAlphaComponent(faded ? 0.5 : 0.95).setStroke()
        dot.lineWidth = faded ? 1 : 2
        dot.stroke()
    }

    private func drawBubble() {
        let duration = DurationMapper.toDuration(pixels: dragDistance, screenHeight: screenHeight)
        let endDate = Date().addingTimeInterval(duration)

        let line1 = TimeFormatter.verbose(duration)
        let line2 = TimeFormatter.endTime(endDate)

        let font1 = NSFont.systemFont(ofSize: 14, weight: .semibold)
        let font2 = NSFont.systemFont(ofSize: 12)

        // High-contrast text — always white on dark bubble
        let attrs1: [NSAttributedString.Key: Any] = [.font: font1, .foregroundColor: NSColor.white]
        let attrs2: [NSAttributedString.Key: Any] = [
            .font: font2,
            .foregroundColor: NSColor.white.withAlphaComponent(0.72)
        ]
        let str1 = NSAttributedString(string: line1, attributes: attrs1)
        let str2 = NSAttributedString(string: line2, attributes: attrs2)
        let s1 = str1.size(), s2 = str2.size()

        let hPad: CGFloat = 14, vPad: CGFloat = 10, gap: CGFloat = 3
        let bW = max(s1.width, s2.width) + hPad * 2
        let bH = s1.height + gap + s2.height + vPad * 2

        let dot = dragEndPoint

        // Position bubble: prefer left, flip right, avoid screen edges
        var bX = dot.x - bW - 16
        if bX < 8 { bX = dot.x + 16 }
        if bX + bW > bounds.width - 8 { bX = dot.x - bW - 16 }
        var bY = dot.y - bH / 2
        bY = max(8, min(bY, bounds.height - bH - 8))

        let bubbleRect = NSRect(x: bX, y: bY, width: bW, height: bH)

        // Drop shadow for legibility over any background
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
        shadow.shadowBlurRadius = 16
        shadow.shadowOffset = NSSize(width: 0, height: -4)
        shadow.set()

        let bg = NSBezierPath(roundedRect: bubbleRect, xRadius: 12, yRadius: 12)
        // Near-black with slight blur effect — readable on light and dark backgrounds
        NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.12, alpha: 0.93).setFill()
        bg.fill()

        // Subtle border for legibility on very dark backgrounds
        NSShadow().set()
        NSColor.white.withAlphaComponent(0.12).setStroke()
        bg.lineWidth = 0.5
        bg.stroke()

        str1.draw(at: NSPoint(x: bX + hPad, y: bY + vPad + s2.height + gap))
        str2.draw(at: NSPoint(x: bX + hPad, y: bY + vPad))
    }

    override var acceptsFirstResponder: Bool { true }
}
