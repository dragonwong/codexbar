// Render a reproducible README illustration using native macOS fonts and AppKit.
// This is a preview with sample data, not a capture of a user's desktop.
import AppKit

let chinese = CommandLine.arguments.contains("--zh")
let width = 1040, height = 280
let image = NSImage(size: NSSize(width: width, height: height))
image.lockFocus()
NSColor(calibratedWhite: 0.95, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()
func text(_ value: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat, color: NSColor, weight: NSFont.Weight = .regular) {
    (value as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight), .foregroundColor: color])
}
func row(y: CGFloat, remaining: Int, dark: Bool) {
    let bg = dark ? NSColor(calibratedWhite: 0.16, alpha: 1) : NSColor(calibratedWhite: 0.88, alpha: 1)
    let fg = dark ? NSColor.white : NSColor(calibratedWhite: 0.12, alpha: 1)
    bg.setFill()
    NSBezierPath(roundedRect: NSRect(x: 36, y: y, width: 968, height: 46), xRadius: 9, yRadius: 9).fill()
    let color: NSColor = remaining > 50 ? NSColor(calibratedRed: 0.12, green: 0.70, blue: 0.35, alpha: 1) : remaining >= 20 ? .systemOrange : .systemRed
    color.setStroke(); color.setFill()
    let center = NSPoint(x: 240, y: y + 18)
    let arc = NSBezierPath()
    arc.appendArc(withCenter: center, radius: 11, startAngle: 180, endAngle: 0, clockwise: true)
    arc.lineWidth = 3; arc.lineCapStyle = .round; arc.stroke()
    let angle = Double(180) * (1 - Double(remaining) / 100) * .pi / 180
    let needle = NSBezierPath()
    needle.move(to: center)
    needle.line(to: NSPoint(x: center.x + cos(angle) * 8, y: center.y + sin(angle) * 8))
    needle.lineWidth = 2.5; needle.lineCapStyle = .round; needle.stroke()
    NSBezierPath(ovalIn: NSRect(x: center.x - 2, y: center.y - 2, width: 4, height: 4)).fill()
    text("5h \(remaining)% · 2h15m / \(chinese ? "周" : "Week") 88% · 10/31", 266, y + 12, size: 18, color: fg, weight: .medium)
    text("19:28", 915, y + 13, size: 16, color: fg)
    text(chinese ? (dark ? "深色" : "浅色") : (dark ? "Dark" : "Light"), 58, y + 13, size: 16, color: fg)
}
row(y: 188, remaining: 82, dark: false)
row(y: 117, remaining: 35, dark: true)
row(y: 46, remaining: 12, dark: false)
image.unlockFocus()
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "docs/images/menu-bar-preview-\(chinese ? "zh-CN" : "en").png"))
