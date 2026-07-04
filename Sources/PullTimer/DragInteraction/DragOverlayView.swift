import AppKit

@MainActor
final class DragOverlayView: NSView {
    var originPoint: NSPoint = .zero
    private(set) var dragDistance: CGFloat = 0
    private var currentPoint: NSPoint = .zero
    private var screenHeight: CGFloat = 900

    var markers: [TimelineMarker] = []

    // MARK: - Trash Can

    private let trashShowThreshold: CGFloat = 600   // overridden per-frame via screenHeight
    private var trashShowDistance: CGFloat { max(400, screenHeight / 2) }
    private let trashCancelThreshold: CGFloat = 58  // within this = cancel zone

    // Center of trash can: horizontally centered, just above the Dock
    private var trashCanCenter: NSPoint {
        let dockTop = NSScreen.main?.visibleFrame.minY ?? 72
        return NSPoint(x: bounds.width / 2, y: dockTop + 52)
    }

    private var trashDistance: CGFloat {
        let dx = currentPoint.x - trashCanCenter.x
        let dy = currentPoint.y - trashCanCenter.y
        return sqrt(dx * dx + dy * dy)
    }

    // 0 = invisible, 1.0 = base size, >1 = enlarged near cancel
    private var trashScale: CGFloat {
        guard !DurationMapper.isInDeadZone(dragDistance) else { return 0 }
        let d = trashDistance
        let showDist = trashShowDistance
        guard d < showDist else { return 0 }
        let t = 1 - max(0, (d - trashCancelThreshold)) / (showDist - trashCancelThreshold)
        let eased = t * t
        return 0.7 + eased * 1.05
    }

    var isInCancelZone: Bool {
        !DurationMapper.isInDeadZone(dragDistance) && trashDistance < trashCancelThreshold
    }

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
        markers = []
        needsDisplay = true
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard dragDistance > 4 else { return }

        let inDeadZone = DurationMapper.isInDeadZone(dragDistance)
        let inCancel = isInCancelZone

        drawLine(faded: inDeadZone || inCancel)

        if !inDeadZone {
            if !inCancel {
                if !markers.isEmpty { drawMarkers() }
                drawBubble()
            }
            drawEndDot(faded: inCancel)
            let s = trashScale
            if s > 0.01 { drawTrashCan(scale: s) }
        } else {
            drawEndDot(faded: true)
        }
    }

    private var dragEndPoint: NSPoint { currentPoint }

    // MARK: - Line

    private func drawLine(faded: Bool) {
        let path = NSBezierPath()
        path.move(to: originPoint)
        path.line(to: dragEndPoint)
        path.lineCapStyle = .round

        let alpha: CGFloat = faded ? 0.25 : 0.9
        NSColor.systemPurple.withAlphaComponent(alpha * 0.25).setStroke()
        path.lineWidth = 5
        path.stroke()
        NSColor.systemPurple.withAlphaComponent(alpha).setStroke()
        path.lineWidth = 2
        path.stroke()
    }

    // MARK: - Trash Can

    private func drawTrashCan(scale: CGFloat) {
        let center = trashCanCenter
        let inCancel = isInCancelZone
        let alpha = min(1.0, (scale - 0.7) / 0.4 + 0.5)

        // Outer glow / background circle
        let bgR: CGFloat = 28 * scale
        let bgRect = NSRect(x: center.x - bgR, y: center.y - bgR,
                            width: bgR * 2, height: bgR * 2)
        let bgPath = NSBezierPath(ovalIn: bgRect)
        let bgColor: NSColor = inCancel
            ? NSColor.systemRed.withAlphaComponent(0.22 * alpha)
            : NSColor.white.withAlphaComponent(0.1 * alpha)
        bgColor.setFill()
        bgPath.fill()

        // Border ring — subtle
        let ringColor: NSColor = inCancel
            ? NSColor.systemRed.withAlphaComponent(0.5 * alpha)
            : NSColor.white.withAlphaComponent(0.2 * alpha)
        ringColor.setStroke()
        bgPath.lineWidth = 1
        bgPath.stroke()

        // SF Symbol icon, tinted
        let pointSize: CGFloat = 20 * scale
        let cfg = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
        let symbolName = inCancel ? "trash.fill" : "trash"
        guard let baseImg = NSImage(systemSymbolName: symbolName,
                                    accessibilityDescription: nil)?
                .withSymbolConfiguration(cfg) else { return }

        let tintColor: NSColor = inCancel
            ? NSColor.systemRed.withAlphaComponent(alpha)
            : NSColor.white.withAlphaComponent(0.85 * alpha)

        // Tint the template image by drawing color over it with sourceAtop
        let tinted = NSImage(size: baseImg.size, flipped: false) { rect in
            baseImg.draw(in: rect)
            tintColor.set()
            rect.fill(using: .sourceAtop)
            return true
        }

        let imgSize = tinted.size
        let imgRect = NSRect(x: center.x - imgSize.width / 2,
                             y: center.y - imgSize.height / 2,
                             width: imgSize.width, height: imgSize.height)
        tinted.draw(in: imgRect, from: .zero, operation: .sourceOver, fraction: 1.0)

        // "Release to cancel" label — only in cancel zone
        if inCancel {
            let font = NSFont.systemFont(ofSize: 11, weight: .medium)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.systemRed.withAlphaComponent(min(1, alpha * 1.2))
            ]
            let str = NSAttributedString(string: "Release to cancel", attributes: attrs)
            let s = str.size()
            str.draw(at: NSPoint(x: center.x - s.width / 2,
                                 y: center.y - imgSize.height / 2 - s.height - 8))
        }
    }

    // MARK: - Markers

    private func drawMarkers() {
        let bubbleRect = computeBubbleRect()
        for marker in markers {
            let pt = pointOnLine(at: marker.position)
            drawDiamond(at: pt, isWarning: marker.isWarning)
            drawMarkerLabel(marker, at: pt, avoidRect: bubbleRect)
        }
    }

    private func pointOnLine(at position: CGFloat) -> NSPoint {
        let dx = dragEndPoint.x - originPoint.x
        let dy = dragEndPoint.y - originPoint.y
        return NSPoint(x: originPoint.x + dx * position,
                       y: originPoint.y + dy * position)
    }

    private func drawDiamond(at center: NSPoint, isWarning: Bool) {
        let s: CGFloat = 6
        let path = NSBezierPath()
        path.move(to: NSPoint(x: center.x,     y: center.y + s))
        path.line(to: NSPoint(x: center.x + s, y: center.y))
        path.line(to: NSPoint(x: center.x,     y: center.y - s))
        path.line(to: NSPoint(x: center.x - s, y: center.y))
        path.close()
        let color: NSColor = isWarning ? .systemOrange : .systemYellow
        color.setFill()
        path.fill()
        NSColor.white.withAlphaComponent(0.85).setStroke()
        path.lineWidth = 1.5
        path.stroke()
    }

    private func drawMarkerLabel(_ marker: TimelineMarker, at pt: NSPoint, avoidRect: NSRect?) {
        let font = NSFont.systemFont(ofSize: 11, weight: .medium)
        let label = "\(marker.time) • \(marker.title)"
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
        let str = NSAttributedString(string: label, attributes: attrs)
        let s = str.size()

        let hPad: CGFloat = 8, vPad: CGFloat = 5
        let lW = s.width + hPad * 2
        let lH = s.height + vPad * 2
        let diamondGap: CGFloat = 10

        var lX = pt.x + diamondGap
        let lY = pt.y - lH / 2

        let rightRect = NSRect(x: lX, y: lY, width: lW, height: lH)
        let wouldOverflow = lX + lW > bounds.width - 8
        let wouldHitBubble = avoidRect.map { rightRect.intersects($0) } ?? false
        if wouldOverflow || wouldHitBubble {
            lX = pt.x - diamondGap - lW
        }

        let labelRect = NSRect(x: lX, y: lY, width: lW, height: lH)

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
        shadow.shadowBlurRadius = 8
        shadow.shadowOffset = NSSize(width: 0, height: -2)
        shadow.set()

        let bg = NSBezierPath(roundedRect: labelRect, xRadius: 5, yRadius: 5)
        NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.12, alpha: 0.85).setFill()
        bg.fill()
        NSShadow().set()

        str.draw(at: NSPoint(x: lX + hPad, y: lY + vPad))
    }

    // MARK: - End Dot

    private func drawEndDot(faded: Bool) {
        let c = dragEndPoint
        let r: CGFloat = faded ? 5 : 7
        let rect = NSRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
        let dot = NSBezierPath(ovalIn: rect)
        let alpha: CGFloat = faded ? 0.25 : 1.0
        NSColor.systemPurple.withAlphaComponent(alpha).setFill()
        dot.fill()
        NSColor.white.withAlphaComponent(faded ? 0.4 : 0.95).setStroke()
        dot.lineWidth = faded ? 1 : 2
        dot.stroke()
    }

    // MARK: - Bubble

    private func computeBubbleRect() -> NSRect {
        let duration = DurationMapper.toDuration(pixels: dragDistance, screenHeight: screenHeight)
        let endDate = Date().addingTimeInterval(duration)
        let line1 = TimeFormatter.verbose(duration)
        let line2 = TimeFormatter.endTime(endDate)

        let font1 = NSFont.systemFont(ofSize: 14, weight: .semibold)
        let font2 = NSFont.systemFont(ofSize: 12)
        let s1 = NSAttributedString(string: line1, attributes: [.font: font1]).size()
        let s2 = NSAttributedString(string: line2, attributes: [.font: font2]).size()

        let hPad: CGFloat = 14, vPad: CGFloat = 10, gap: CGFloat = 3
        let bW = max(s1.width, s2.width) + hPad * 2
        let bH = s1.height + gap + s2.height + vPad * 2
        let dot = dragEndPoint

        var bX = dot.x - bW - 16
        if bX < 8 { bX = dot.x + 16 }
        if bX + bW > bounds.width - 8 { bX = dot.x - bW - 16 }
        var bY = dot.y - bH / 2
        bY = max(8, min(bY, bounds.height - bH - 8))
        return NSRect(x: bX, y: bY, width: bW, height: bH)
    }

    private func drawBubble() {
        let duration = DurationMapper.toDuration(pixels: dragDistance, screenHeight: screenHeight)
        let endDate = Date().addingTimeInterval(duration)
        let line1 = TimeFormatter.verbose(duration)
        let line2 = TimeFormatter.endTime(endDate)

        let font1 = NSFont.systemFont(ofSize: 14, weight: .semibold)
        let font2 = NSFont.systemFont(ofSize: 12)
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

        var bX = dot.x - bW - 16
        if bX < 8 { bX = dot.x + 16 }
        if bX + bW > bounds.width - 8 { bX = dot.x - bW - 16 }
        var bY = dot.y - bH / 2
        bY = max(8, min(bY, bounds.height - bH - 8))

        let bubbleRect = NSRect(x: bX, y: bY, width: bW, height: bH)

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
        shadow.shadowBlurRadius = 16
        shadow.shadowOffset = NSSize(width: 0, height: -4)
        shadow.set()

        let bg = NSBezierPath(roundedRect: bubbleRect, xRadius: 12, yRadius: 12)
        NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.12, alpha: 0.93).setFill()
        bg.fill()

        NSShadow().set()
        NSColor.white.withAlphaComponent(0.12).setStroke()
        bg.lineWidth = 0.5
        bg.stroke()

        str2.draw(at: NSPoint(x: bX + hPad, y: bY + vPad))
        str1.draw(at: NSPoint(x: bX + hPad, y: bY + vPad + s2.height + gap))
    }

    override var acceptsFirstResponder: Bool { true }
}
