import AppKit

enum MenuBarIcon {
    /// ~20% larger than the original 16pt symbol.
    static let pointSize: CGFloat = 20

    static func image(active: Bool) -> NSImage {
        let size = NSSize(width: pointSize, height: pointSize)
        let image = NSImage(size: size, flipped: false) { rect in
            drawHourglass(in: rect, active: active)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func drawHourglass(in rect: NSRect, active: Bool) {
        let cx = rect.midX
        let cy = rect.midY
        let halfW: CGFloat = 5.2
        let halfH: CGFloat = 7.4
        let waist: CGFloat = 1.15
        let lineWidth: CGFloat = active ? 1.55 : 1.35

        NSColor.black.setStroke()
        NSColor.black.setFill()

        let capH: CGFloat = 1.35
        let capW = halfW * 2 + 1.2
        NSBezierPath(roundedRect: NSRect(x: cx - capW / 2, y: cy + halfH - 0.15, width: capW, height: capH),
                     xRadius: 0.5, yRadius: 0.5).fill()
        NSBezierPath(roundedRect: NSRect(x: cx - capW / 2, y: cy - halfH - capH + 0.15, width: capW, height: capH),
                     xRadius: 0.5, yRadius: 0.5).fill()

        let glass = NSBezierPath()
        glass.move(to: NSPoint(x: cx - halfW, y: cy + halfH))
        glass.line(to: NSPoint(x: cx + halfW, y: cy + halfH))
        glass.line(to: NSPoint(x: cx + waist, y: cy))
        glass.line(to: NSPoint(x: cx + halfW, y: cy - halfH))
        glass.line(to: NSPoint(x: cx - halfW, y: cy - halfH))
        glass.line(to: NSPoint(x: cx - waist, y: cy))
        glass.close()
        glass.lineWidth = lineWidth
        glass.lineJoinStyle = .round
        glass.stroke()

        if active {
            let sand = NSBezierPath()
            sand.move(to: NSPoint(x: cx - halfW + 1.4, y: cy - halfH + 0.6))
            sand.line(to: NSPoint(x: cx + halfW - 1.4, y: cy - halfH + 0.6))
            sand.line(to: NSPoint(x: cx, y: cy - 1.6))
            sand.close()
            sand.fill()
        }
    }
}
