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
        return NSPoint(x: bounds.width / 2, y: dockTop + 52)
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

    private var hourglassRotation: CGFloat {
        dragDistance * 0.026
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

        drawLine(faded: inDeadZone || inCancel)

        if !inDeadZone {
            if !inCancel {
                drawBubble()
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

        let alpha: CGFloat = faded ? 0.22 : 0.9
        Theme.NS.sand.withAlphaComponent(alpha * 0.22).setStroke()
        path.lineWidth = 6
        path.stroke()
        Theme.NS.teal.withAlphaComponent(alpha).setStroke()
        path.lineWidth = 2
        path.stroke()
    }

    // MARK: - Hourglass

    private func drawHourglass(at center: NSPoint, faded: Bool, rotation: CGFloat, progress: CGFloat) {
        let alpha: CGFloat = faded ? 0.28 : 1.0
        let size: CGFloat = faded ? 30 : 38

        NSGraphicsContext.current?.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: center.x, yBy: center.y)
        transform.rotate(byRadians: rotation)
        transform.concat()

        drawSpinRing(size: size, rotation: rotation, alpha: alpha)
        drawHourglassBody(size: size, progress: progress, alpha: alpha)

        NSGraphicsContext.current?.restoreGraphicsState()
    }

    private func drawSpinRing(size: CGFloat, rotation: CGFloat, alpha: CGFloat) {
        let radius = size * 0.78
        let start = CGFloat(rotation) * 180 / .pi
        let ring = NSBezierPath()
        ring.appendArc(
            withCenter: .zero,
            radius: radius,
            startAngle: start,
            endAngle: start + 250,
            clockwise: false
        )
        ring.lineWidth = 1.4
        ring.lineCapStyle = .round
        Theme.NS.glass.withAlphaComponent(0.55 * alpha).setStroke()
        ring.stroke()

        let beadAngle = (start + 250) * .pi / 180
        let bead = NSPoint(x: cos(beadAngle) * radius, y: sin(beadAngle) * radius)
        let beadR: CGFloat = 2.2
        Theme.NS.sand.withAlphaComponent(0.95 * alpha).setFill()
        NSBezierPath(ovalIn: NSRect(x: bead.x - beadR, y: bead.y - beadR, width: beadR * 2, height: beadR * 2)).fill()
    }

    private func drawHourglassBody(size: CGFloat, progress: CGFloat, alpha: CGFloat) {
        let halfW = size * 0.28
        let halfH = size * 0.38
        let waist: CGFloat = size * 0.055

        let top = NSBezierPath()
        top.move(to: NSPoint(x: -halfW, y: halfH))
        top.line(to: NSPoint(x: halfW, y: halfH))
        top.line(to: NSPoint(x: waist, y: 0))
        top.line(to: NSPoint(x: -waist, y: 0))
        top.close()

        let bottom = NSBezierPath()
        bottom.move(to: NSPoint(x: -halfW, y: -halfH))
        bottom.line(to: NSPoint(x: halfW, y: -halfH))
        bottom.line(to: NSPoint(x: waist, y: 0))
        bottom.line(to: NSPoint(x: -waist, y: 0))
        bottom.close()

        Theme.NS.glass.withAlphaComponent(0.22 * alpha).setFill()
        top.fill()
        bottom.fill()

        let topSand = min(1, max(0, 1 - progress))
        if topSand > 0.04 {
            NSGraphicsContext.current?.saveGraphicsState()
            top.addClip()
            let sandTop = halfH - (halfH * (1 - topSand) * 0.72)
            let sand = NSBezierPath()
            sand.move(to: NSPoint(x: -halfW, y: sandTop))
            sand.line(to: NSPoint(x: halfW, y: sandTop))
            sand.line(to: NSPoint(x: 0, y: 0))
            sand.close()
            Theme.NS.sand.withAlphaComponent(0.92 * alpha).setFill()
            sand.fill()
            NSGraphicsContext.current?.restoreGraphicsState()
        }

        let bottomSand = min(1, max(0, progress))
        if bottomSand > 0.04 {
            NSGraphicsContext.current?.saveGraphicsState()
            bottom.addClip()
            let rise = halfH * bottomSand * 0.78
            let sand = NSBezierPath()
            sand.move(to: NSPoint(x: -halfW, y: -halfH))
            sand.line(to: NSPoint(x: halfW, y: -halfH))
            sand.line(to: NSPoint(x: 0, y: -halfH + rise))
            sand.close()
            Theme.NS.sand.withAlphaComponent(0.95 * alpha).setFill()
            sand.fill()
            NSGraphicsContext.current?.restoreGraphicsState()
        }

        Theme.NS.teal.withAlphaComponent(0.85 * alpha).setStroke()
        top.lineWidth = 1.6
        top.lineJoinStyle = .round
        top.stroke()
        bottom.lineWidth = 1.6
        bottom.lineJoinStyle = .round
        bottom.stroke()

        Theme.NS.glass.withAlphaComponent(0.7 * alpha).setStroke()
        let highlight = NSBezierPath()
        highlight.move(to: NSPoint(x: -halfW + 1.5, y: halfH - 1))
        highlight.line(to: NSPoint(x: -waist - 0.4, y: 2))
        highlight.lineWidth = 1
        highlight.lineCapStyle = .round
        highlight.stroke()

        let capW = halfW * 2 + 3
        let capH: CGFloat = 3.2
        Theme.NS.brass.withAlphaComponent(alpha).setFill()
        NSBezierPath(roundedRect: NSRect(x: -capW / 2, y: halfH - 0.4, width: capW, height: capH),
                     xRadius: 1, yRadius: 1).fill()
        NSBezierPath(roundedRect: NSRect(x: -capW / 2, y: -halfH - capH + 0.4, width: capW, height: capH),
                     xRadius: 1, yRadius: 1).fill()
        Theme.NS.sandLight.withAlphaComponent(0.55 * alpha).setFill()
        NSBezierPath(roundedRect: NSRect(x: -capW / 2 + 1, y: halfH + 1.1, width: capW - 2, height: 1.1),
                     xRadius: 0.4, yRadius: 0.4).fill()
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

    // MARK: - Bubble

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
            .foregroundColor: Theme.NS.sandLight.withAlphaComponent(0.88)
        ]
        let str1 = NSAttributedString(string: line1, attributes: attrs1)
        let str2 = NSAttributedString(string: line2, attributes: attrs2)
        let s1 = str1.size(), s2 = str2.size()

        let hPad: CGFloat = 14, vPad: CGFloat = 10, gap: CGFloat = 3
        let bW = max(s1.width, s2.width) + hPad * 2
        let bH = s1.height + gap + s2.height + vPad * 2
        let dot = dragEndPoint

        var bX = dot.x - bW - 22
        if bX < 8 { bX = dot.x + 22 }
        if bX + bW > bounds.width - 8 { bX = dot.x - bW - 22 }
        var bY = dot.y - bH / 2
        bY = max(8, min(bY, bounds.height - bH - 8))

        let bubbleRect = NSRect(x: bX, y: bY, width: bW, height: bH)

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
        shadow.shadowBlurRadius = 16
        shadow.shadowOffset = NSSize(width: 0, height: -4)
        shadow.set()

        let bg = NSBezierPath(roundedRect: bubbleRect, xRadius: 12, yRadius: 12)
        Theme.NS.glassDark.setFill()
        bg.fill()

        NSShadow().set()
        Theme.NS.teal.withAlphaComponent(0.45).setStroke()
        bg.lineWidth = 0.8
        bg.stroke()

        str2.draw(at: NSPoint(x: bX + hPad, y: bY + vPad))
        str1.draw(at: NSPoint(x: bX + hPad, y: bY + vPad + s2.height + gap))
    }

    override var acceptsFirstResponder: Bool { true }
}
