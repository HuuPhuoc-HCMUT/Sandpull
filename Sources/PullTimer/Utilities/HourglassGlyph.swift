import AppKit

enum HourglassGlyph {
    /// Same hourglass as the drag line. `size` is the design size used while dragging (42).
    static func draw(size: CGFloat, progress: CGFloat, alpha: CGFloat = 1, onClock: Bool = false) {
        let s = size / 42
        let halfW = size * 0.28
        let halfH = size * 0.38
        let waist = size * 0.055

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

        Theme.NS.glass.withAlphaComponent(0.55 * alpha).setFill()
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

        (onClock ? Theme.NS.sand : Theme.NS.teal).withAlphaComponent(alpha).setStroke()
        top.lineWidth = (onClock ? 2.4 : 2.0) * s
        top.lineJoinStyle = .round
        top.stroke()
        bottom.lineWidth = (onClock ? 2.4 : 2.0) * s
        bottom.lineJoinStyle = .round
        bottom.stroke()

        Theme.NS.glass.withAlphaComponent(0.7 * alpha).setStroke()
        let highlight = NSBezierPath()
        highlight.move(to: NSPoint(x: -halfW + 1.5 * s, y: halfH - 1 * s))
        highlight.line(to: NSPoint(x: -waist - 0.4 * s, y: 2 * s))
        highlight.lineWidth = 1 * s
        highlight.lineCapStyle = .round
        highlight.stroke()

        let capW = halfW * 2 + 3 * s
        let capH = 3.2 * s
        Theme.NS.brass.withAlphaComponent(alpha).setFill()
        NSBezierPath(roundedRect: NSRect(x: -capW / 2, y: halfH - 0.4 * s, width: capW, height: capH),
                     xRadius: s, yRadius: s).fill()
        NSBezierPath(roundedRect: NSRect(x: -capW / 2, y: -halfH - capH + 0.4 * s, width: capW, height: capH),
                     xRadius: s, yRadius: s).fill()
        Theme.NS.sandLight.withAlphaComponent(0.55 * alpha).setFill()
        NSBezierPath(roundedRect: NSRect(x: -capW / 2 + s, y: halfH + 1.1 * s, width: capW - 2 * s, height: 1.1 * s),
                     xRadius: 0.4 * s, yRadius: 0.4 * s).fill()
    }
}
