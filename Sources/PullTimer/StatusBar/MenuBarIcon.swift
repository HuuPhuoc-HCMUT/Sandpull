import AppKit

enum MenuBarIcon {
    static let pointSize: CGFloat = 22

    /// `progress` 0 = sand on top, 1 = sand on bottom.
    static func image(progress: CGFloat) -> NSImage {
        let p = min(1, max(0, progress))
        let size = NSSize(width: pointSize, height: pointSize)
        let image = NSImage(size: size, flipped: false) { rect in
            drawHourglass(in: rect, progress: p)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func drawHourglass(in rect: NSRect, progress: CGFloat) {
        let cx = rect.midX
        let cy = rect.midY
        let halfW: CGFloat = 5.6
        let halfH: CGFloat = 7.8
        let waist: CGFloat = 1.2
        let lineWidth: CGFloat = 1.7

        NSColor.black.setStroke()
        NSColor.black.setFill()

        let capH: CGFloat = 1.45
        let capW = halfW * 2 + 1.4
        NSBezierPath(roundedRect: NSRect(x: cx - capW / 2, y: cy + halfH - 0.15, width: capW, height: capH),
                     xRadius: 0.5, yRadius: 0.5).fill()
        NSBezierPath(roundedRect: NSRect(x: cx - capW / 2, y: cy - halfH - capH + 0.15, width: capW, height: capH),
                     xRadius: 0.5, yRadius: 0.5).fill()

        let top = NSBezierPath()
        top.move(to: NSPoint(x: cx - halfW, y: cy + halfH))
        top.line(to: NSPoint(x: cx + halfW, y: cy + halfH))
        top.line(to: NSPoint(x: cx + waist, y: cy))
        top.line(to: NSPoint(x: cx - waist, y: cy))
        top.close()

        let bottom = NSBezierPath()
        bottom.move(to: NSPoint(x: cx - halfW, y: cy - halfH))
        bottom.line(to: NSPoint(x: cx + halfW, y: cy - halfH))
        bottom.line(to: NSPoint(x: cx + waist, y: cy))
        bottom.line(to: NSPoint(x: cx - waist, y: cy))
        bottom.close()

        let topSand = 1 - progress
        if topSand > 0.06 {
            NSGraphicsContext.current?.saveGraphicsState()
            top.addClip()
            let inset = halfH * (1 - topSand) * 0.7
            let sand = NSBezierPath()
            sand.move(to: NSPoint(x: cx - halfW + 0.8, y: cy + halfH - inset))
            sand.line(to: NSPoint(x: cx + halfW - 0.8, y: cy + halfH - inset))
            sand.line(to: NSPoint(x: cx, y: cy + 0.4))
            sand.close()
            sand.fill()
            NSGraphicsContext.current?.restoreGraphicsState()
        }

        if progress > 0.06 {
            NSGraphicsContext.current?.saveGraphicsState()
            bottom.addClip()
            let rise = halfH * progress * 0.78
            let sand = NSBezierPath()
            sand.move(to: NSPoint(x: cx - halfW + 0.8, y: cy - halfH + 0.4))
            sand.line(to: NSPoint(x: cx + halfW - 0.8, y: cy - halfH + 0.4))
            sand.line(to: NSPoint(x: cx, y: cy - halfH + rise))
            sand.close()
            sand.fill()
            NSGraphicsContext.current?.restoreGraphicsState()
        }

        let glass = NSBezierPath()
        glass.append(top)
        glass.append(bottom)
        glass.lineWidth = lineWidth
        glass.lineJoinStyle = .round
        glass.stroke()
    }
}
