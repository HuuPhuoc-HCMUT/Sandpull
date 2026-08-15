import AppKit

@MainActor
final class DragOverlayView: NSView {
    var originPoint: NSPoint = .zero
    private(set) var dragDistance: CGFloat = 0
    private var currentPoint: NSPoint = .zero
    private var screenHeight: CGFloat = 900

    // MARK: - Trash Can

    private var trashShowDistance: CGFloat { max(400, screenHeight / 2) }
    private let trashCancelThreshold: CGFloat = 58

    private var trashCanCenter: NSPoint {
        let dockTop = NSScreen.main?.visibleFrame.minY ?? 72
        return NSPoint(x: bounds.width / 2, y: dockTop + 92 * 1.15)
    }

    private var trashDistance: CGFloat {
        let dx = currentPoint.x - trashCanCenter.x
        let dy = currentPoint.y - trashCanCenter.y
        return sqrt(dx * dx + dy * dy)
    }

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

    private var prefersReducedMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    private var hourglassRotation: CGFloat {
        guard AppSettings.shared.rotateHourglass, !prefersReducedMotion else { return 0 }
        return dragDistance * 0.038
    }

    private var sandProgress: CGFloat {
        let usable = max(400, screenHeight - 24) - DurationMapper.deadZone
        return min(1, max(0, (dragDistance - DurationMapper.deadZone) / usable))
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
        needsDisplay = true
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard dragDistance > 4 else { return }

        let inDeadZone = DurationMapper.isInDeadZone(dragDistance)
        let inCancel = isInCancelZone
        let duration = DurationMapper.toDuration(pixels: dragDistance, screenHeight: screenHeight)
        let onClock = !inDeadZone && !inCancel
            && AppSettings.shared.highlightQuarterHours
            && DurationMapper.clockQuarterSlot(for: duration) != nil

        drawLine(faded: inDeadZone || inCancel)

        if !inDeadZone {
            if !inCancel {
                drawBubble(duration: duration, onClock: onClock)
            }
            drawHourglass(
                at: dragEndPoint,
                faded: inCancel,
                rotation: hourglassRotation,
                progress: sandProgress
            )
            let s = trashScale
            if s > 0.01 { drawTrashCan(scale: s) }
        } else {
            drawHourglass(at: dragEndPoint, faded: true, rotation: hourglassRotation * 0.35, progress: 0)
        }
    }

    private var dragEndPoint: NSPoint { currentPoint }

    // MARK: - Line

    private func drawLine(faded: Bool) {
        let path = NSBezierPath()
        path.move(to: originPoint)
        path.line(to: dragEndPoint)
        path.lineCapStyle = .round

        let alpha: CGFloat = faded ? 0.28 : 1.0
        Theme.NS.teal.withAlphaComponent(alpha * 0.28).setStroke()
        path.lineWidth = 8.1
        path.stroke()
        Theme.NS.teal.withAlphaComponent(alpha).setStroke()
        path.lineWidth = 3.6
        path.stroke()
    }

    // MARK: - Hourglass

    private func drawHourglass(at center: NSPoint, faded: Bool, rotation: CGFloat, progress: CGFloat) {
        let alpha: CGFloat = faded ? 0.28 : 1.0
        let size: CGFloat = faded ? 32 : 42

        NSGraphicsContext.current?.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: center.x, yBy: center.y)
        transform.rotate(byRadians: rotation)
        transform.concat()
        HourglassGlyph.draw(size: size, progress: progress, alpha: alpha)
        NSGraphicsContext.current?.restoreGraphicsState()
    }

    // MARK: - Trash Can

    private func drawTrashCan(scale: CGFloat) {
        let center = trashCanCenter
        let inCancel = isInCancelZone
        let alpha = min(1.0, (scale - 0.7) / 0.4 + 0.5)

        let bgR: CGFloat = 28 * scale
        let bgRect = NSRect(x: center.x - bgR, y: center.y - bgR,
                            width: bgR * 2, height: bgR * 2)
        let bgPath = NSBezierPath(ovalIn: bgRect)
        let bgColor: NSColor = inCancel
            ? NSColor.systemRed.withAlphaComponent(0.22 * alpha)
            : Theme.NS.glassDark.withAlphaComponent(0.35 * alpha)
        bgColor.setFill()
        bgPath.fill()

        let ringColor: NSColor = inCancel
            ? NSColor.systemRed.withAlphaComponent(0.5 * alpha)
            : Theme.NS.teal.withAlphaComponent(0.35 * alpha)
        ringColor.setStroke()
        bgPath.lineWidth = 1
        bgPath.stroke()

        let pointSize: CGFloat = 20 * scale
        let cfg = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
        let symbolName = inCancel ? "trash.fill" : "trash"
        guard let baseImg = NSImage(systemSymbolName: symbolName,
                                    accessibilityDescription: nil)?
                .withSymbolConfiguration(cfg) else { return }

        let tintColor: NSColor = inCancel
            ? NSColor.systemRed.withAlphaComponent(alpha)
            : Theme.NS.sandLight.withAlphaComponent(0.9 * alpha)

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
    }

    // MARK: - Bubble

    private func drawBubble(duration: TimeInterval, onClock: Bool) {
        let endDate = Date().addingTimeInterval(duration)
        let line1 = TimeFormatter.verbose(duration)
        let line2 = TimeFormatter.endTime(endDate)

        let font1 = NSFont.systemFont(ofSize: 14, weight: .semibold)
        let font2 = NSFont.systemFont(ofSize: 12)
        let attrs1: [NSAttributedString.Key: Any] = [
            .font: font1,
            .foregroundColor: onClock ? Theme.NS.sandLight : NSColor.white
        ]
        let attrs2: [NSAttributedString.Key: Any] = [
            .font: font2,
            .foregroundColor: onClock
                ? Theme.NS.sand.withAlphaComponent(0.9)
                : Theme.NS.sandLight.withAlphaComponent(0.88)
        ]
        let str1 = NSAttributedString(string: line1, attributes: attrs1)
        let str2 = NSAttributedString(string: line2, attributes: attrs2)
        let s1 = str1.size(), s2 = str2.size()

        let hPad: CGFloat = 14, vPad: CGFloat = 10, gap: CGFloat = 3
        let bW = max(s1.width, s2.width) + hPad * 2
        let bH = s1.height + gap + s2.height + vPad * 2
        let dot = dragEndPoint

        let bubbleGap: CGFloat = 38
        var bX = dot.x - bW - bubbleGap
        if bX < 8 { bX = dot.x + bubbleGap }
        if bX + bW > bounds.width - 8 { bX = dot.x - bW - bubbleGap }
        var bY = dot.y - bH / 2
        bY = max(8, min(bY, bounds.height - bH - 8))

        let bubbleRect = NSRect(x: bX, y: bY, width: bW, height: bH)

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
        shadow.shadowBlurRadius = 16
        shadow.shadowOffset = NSSize(width: 0, height: -4)
        shadow.set()

        let bg = NSBezierPath(roundedRect: bubbleRect, xRadius: 12, yRadius: 12)
        if onClock {
            NSColor(calibratedRed: 0.32, green: 0.28, blue: 0.18, alpha: 0.94).setFill()
        } else {
            Theme.NS.glassPanel.setFill()
        }
        bg.fill()

        NSShadow().set()
        (onClock ? Theme.NS.sand : Theme.NS.teal).withAlphaComponent(onClock ? 0.9 : 0.7).setStroke()
        bg.lineWidth = 1
        bg.stroke()

        str2.draw(at: NSPoint(x: bX + hPad, y: bY + vPad))
        str1.draw(at: NSPoint(x: bX + hPad, y: bY + vPad + s2.height + gap))
    }

    override var acceptsFirstResponder: Bool { true }
}
