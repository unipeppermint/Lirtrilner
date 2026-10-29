import AppKit

let size = 1024
let bitmap = NSBitmapImageRep(
  bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 3,
  hasAlpha: false, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
func color(_ value: Int) -> NSColor {
  NSColor(
    red: CGFloat((value >> 16) & 255) / 255, green: CGFloat((value >> 8) & 255) / 255,
    blue: CGFloat(value & 255) / 255, alpha: 1)
}
func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: NSColor, _ r: CGFloat) {
  c.setFill()
  NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: r, yRadius: r).fill()
}
func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: NSColor) {
  c.setFill()
  NSBezierPath(ovalIn: NSRect(x: x, y: y, width: w, height: h)).fill()
}
let cream = color(0xFFF7E8)
let red = color(0xB73E2B)
let ink = color(0x35271F)
let gold = color(0xD9A34C)
box(0, 0, 1024, 1024, color(0xF1E2CA), 0)
oval(98, 70, 828, 828, cream)
box(262, 108, 500, 302, red, 80)
box(334, 160, 356, 194, cream, 45)
box(484, 796, 56, 98, gold, 20)
oval(460, 867, 104, 104, red)
oval(141, 486, 150, 218, gold)
oval(733, 486, 150, 218, gold)
box(217, 357, 590, 477, red, 115)
box(270, 410, 484, 366, cream, 85)
oval(348, 555, 65, 91, ink)
oval(611, 555, 65, 91, ink)
oval(363, 606, 18, 22, .white)
oval(626, 606, 18, 22, .white)
oval(310, 491, 71, 31, color(0xE9B19A))
oval(643, 491, 71, 31, color(0xE9B19A))
let smile = NSBezierPath()
smile.move(to: NSPoint(x: 461, y: 513))
smile.curve(
  to: NSPoint(x: 563, y: 513), controlPoint1: NSPoint(x: 470, y: 449),
  controlPoint2: NSPoint(x: 554, y: 449))
smile.lineWidth = 15
smile.lineCapStyle = .round
ink.setStroke()
smile.stroke()
oval(457, 205, 110, 110, gold)
oval(489, 237, 46, 46, ink)
NSGraphicsContext.restoreGraphicsState()
let url = URL(fileURLWithPath: CommandLine.arguments[1])
try bitmap.representation(using: .png, properties: [:])!.write(to: url)
