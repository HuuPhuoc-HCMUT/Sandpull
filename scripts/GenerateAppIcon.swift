#!/usr/bin/env swift
import AppKit

let teal = NSColor(calibratedRed: 0.36, green: 0.76, blue: 0.80, alpha: 1)
let tealDeep = NSColor(calibratedRed: 0.18, green: 0.52, blue: 0.58, alpha: 1)
let sand = NSColor(calibratedRed: 0.90, green: 0.74, blue: 0.46, alpha: 1)
let sandLight = NSColor(calibratedRed: 0.97, green: 0.88, blue: 0.68, alpha: 1)
let glass = NSColor(calibratedRed: 0.86, green: 0.95, blue: 0.96, alpha: 0.88)
let glassDark = NSColor(calibratedRed: 0.16, green: 0.28, blue: 0.32, alpha: 1)
let brass = NSColor(calibratedRed: 0.70, green: 0.56, blue: 0.34, alpha: 1)

func brighter(_ color: NSColor, by factor: CGFloat) -> NSColor {
    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    color.usingColorSpace(.deviceRGB)!.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
    return NSColor(calibratedHue: h, saturation: s, brightness: min(1, b * factor), alpha: a)
}

func drawHourglass(size: CGFloat, progress: CGFloat) {
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

    glass.withAlphaComponent(0.55).setFill()
    top.fill()
    bottom.fill()

    NSGraphicsContext.current?.saveGraphicsState()
    top.addClip()
    let sandTop = halfH - (halfH * progress * 0.72)
    let topSand = NSBezierPath()
    topSand.move(to: NSPoint(x: -halfW, y: sandTop))
    topSand.line(to: NSPoint(x: halfW, y: sandTop))
    topSand.line(to: NSPoint(x: 0, y: 0))
    topSand.close()
    sand.withAlphaComponent(0.92).setFill()
    topSand.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    NSGraphicsContext.current?.saveGraphicsState()
    bottom.addClip()
    let rise = halfH * progress * 0.78
    let botSand = NSBezierPath()
    botSand.move(to: NSPoint(x: -halfW, y: -halfH))
    botSand.line(to: NSPoint(x: halfW, y: -halfH))
    botSand.line(to: NSPoint(x: 0, y: -halfH + rise))
    botSand.close()
    sand.withAlphaComponent(0.95).setFill()
    botSand.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    teal.setStroke()
    top.lineWidth = 2.0 * s
    top.lineJoinStyle = .round
    top.stroke()
    bottom.lineWidth = 2.0 * s
    bottom.lineJoinStyle = .round
    bottom.stroke()

    glass.withAlphaComponent(0.7).setStroke()
    let highlight = NSBezierPath()
    highlight.move(to: NSPoint(x: -halfW + 1.5 * s, y: halfH - s))
    highlight.line(to: NSPoint(x: -waist - 0.4 * s, y: 2 * s))
    highlight.lineWidth = s
    highlight.lineCapStyle = .round
    highlight.stroke()

    let capW = halfW * 2 + 3 * s
    let capH = 3.2 * s
    brass.setFill()
    NSBezierPath(roundedRect: NSRect(x: -capW / 2, y: halfH - 0.4 * s, width: capW, height: capH),
                 xRadius: s, yRadius: s).fill()
    NSBezierPath(roundedRect: NSRect(x: -capW / 2, y: -halfH - capH + 0.4 * s, width: capW, height: capH),
                 xRadius: s, yRadius: s).fill()
    sandLight.withAlphaComponent(0.55).setFill()
    NSBezierPath(roundedRect: NSRect(x: -capW / 2 + s, y: halfH + 1.1 * s, width: capW - 2 * s, height: 1.1 * s),
                 xRadius: 0.4 * s, yRadius: 0.4 * s).fill()
}

func render(pixelSize: Int) -> NSBitmapImageRep {
    let scale: CGFloat = 1
    let size = CGFloat(pixelSize)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    ctx.shouldAntialias = true
    ctx.imageInterpolation = .high
    NSGraphicsContext.current = ctx

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let bg = NSBezierPath(rect: rect)
    brighter(glassDark, by: 1.15).setFill()
    bg.fill()
    brighter(tealDeep, by: 1.15).withAlphaComponent(0.55).setFill()
    bg.fill()

    NSGraphicsContext.current?.saveGraphicsState()
    let transform = NSAffineTransform()
    transform.translateX(by: size / 2, yBy: size / 2)
    transform.concat()
    drawHourglass(size: size * 0.62, progress: 0.38)
    NSGraphicsContext.current?.restoreGraphicsState()

    NSGraphicsContext.restoreGraphicsState()
    _ = scale
    return rep
}

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : FileManager.default.currentDirectoryPath)
let iconset = root.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let specs: [(name: String, px: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for spec in specs {
    let rep = render(pixelSize: spec.px)
    let data = rep.representation(using: .png, properties: [:])!
    try data.write(to: iconset.appendingPathComponent(spec.name))
}

let icns = root.appendingPathComponent("AppIcon.icns")
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", icns.path]
try task.run()
task.waitUntilExit()
guard task.terminationStatus == 0 else {
    fatalError("iconutil failed")
}
try? FileManager.default.removeItem(at: iconset)
print("Wrote \(icns.path)")

let webDir = root.appendingPathComponent("website/assets")
if FileManager.default.fileExists(atPath: webDir.path) {
    let webIcon = webDir.appendingPathComponent("app-icon.png")
    let webIcon256 = webDir.appendingPathComponent("app-icon-256.png")
    try render(pixelSize: 1024).representation(using: .png, properties: [:])!.write(to: webIcon)
    try render(pixelSize: 256).representation(using: .png, properties: [:])!.write(to: webIcon256)
    print("Wrote \(webIcon.path)")
    print("Wrote \(webIcon256.path)")
}
