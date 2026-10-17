// Generates Scribo's app icon as a 1024x1024 PNG using CoreGraphics/AppKit.
// Run:  swift tools/make-icon.swift [output.png]
// The build script (make-icon.sh) turns the PNG into a .icns.
import AppKit

func color(_ hex: String, _ a: CGFloat = 1) -> NSColor {
    var s = hex; if s.hasPrefix("#") { s.removeFirst() }
    let v = UInt64(s, radix: 16) ?? 0
    return NSColor(srgbRed: CGFloat((v >> 16) & 0xFF)/255,
                   green: CGFloat((v >> 8) & 0xFF)/255,
                   blue: CGFloat(v & 0xFF)/255, alpha: a)
}

let S: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S),
                          bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                          isPlanar: false, colorSpaceName: .deviceRGB,
                          bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx
ctx.cgContext.setAllowsAntialiasing(true)

// ---- Rounded-square ("squircle") background, Big Sur grid proportions ----
let margin: CGFloat = 100
let squircle = NSRect(x: margin, y: margin, width: S - 2*margin, height: S - 2*margin)
let bgPath = NSBezierPath(roundedRect: squircle, xRadius: 185, yRadius: 185)

// Gradient fill
let grad = NSGradient(starting: color("#8B7CF8"), ending: color("#5721C9"))!
bgPath.addClip()
grad.draw(in: squircle, angle: -90)

// Soft top highlight
let hi = NSGradient(starting: color("#FFFFFF", 0.22), ending: color("#FFFFFF", 0.0))!
hi.draw(in: squircle, angle: -90)

// ---- The "ink" squiggle being drawn (starts at the pencil tip) ----
let squiggle = NSBezierPath()
squiggle.lineWidth = 44
squiggle.lineCapStyle = .round
squiggle.lineJoinStyle = .round
squiggle.move(to: CGPoint(x: 322, y: 412))
squiggle.curve(to: CGPoint(x: 500, y: 452),
               controlPoint1: CGPoint(x: 392, y: 470),
               controlPoint2: CGPoint(x: 438, y: 470))
squiggle.curve(to: CGPoint(x: 700, y: 412),
               controlPoint1: CGPoint(x: 572, y: 432),
               controlPoint2: CGPoint(x: 618, y: 372))
color("#FFD23F").setStroke()
squiggle.stroke()

// ---- Pencil (drawn horizontally in a local frame, then rotated) ----
func drawPencil() {
    let tipColor = color("#2E2A3A")
    let woodColor = color("#F2C79B")
    let bodyColor = color("#FF5E8A")
    let ferrule = color("#DADDE3")
    let eraser = color("#7FD1C9")

    // Local x axis points toward the tip (+x). Centered at origin.
    let halfH: CGFloat = 78
    let tipX: CGFloat = 300
    let woodBackX: CGFloat = 200
    let bodyFrontX: CGFloat = 200
    let ferruleX: CGFloat = -230
    let bandX: CGFloat = -200
    let eraserX: CGFloat = -300

    // Eraser cap (rounded)
    let eraserRect = NSRect(x: eraserX, y: -halfH, width: bandX - eraserX, height: 2*halfH)
    let eraserPath = NSBezierPath(roundedRect: eraserRect, xRadius: 40, yRadius: 40)
    eraser.setFill(); eraserPath.fill()

    // Ferrule band
    ferrule.setFill()
    NSBezierPath(rect: NSRect(x: bandX, y: -halfH, width: ferruleX - bandX, height: 2*halfH)).fill()

    // Body
    bodyColor.setFill()
    NSBezierPath(rect: NSRect(x: ferruleX, y: -halfH, width: bodyFrontX - ferruleX, height: 2*halfH)).fill()

    // Wood cone
    let wood = NSBezierPath()
    wood.move(to: CGPoint(x: woodBackX, y: halfH))
    wood.line(to: CGPoint(x: tipX - 46, y: 24))
    wood.line(to: CGPoint(x: tipX - 46, y: -24))
    wood.line(to: CGPoint(x: woodBackX, y: -halfH))
    wood.close()
    woodColor.setFill(); wood.fill()

    // Graphite tip
    let tip = NSBezierPath()
    tip.move(to: CGPoint(x: tipX - 46, y: 24))
    tip.line(to: CGPoint(x: tipX, y: 0))
    tip.line(to: CGPoint(x: tipX - 46, y: -24))
    tip.close()
    tipColor.setFill(); tip.fill()
}

NSGraphicsContext.saveGraphicsState()
let t = NSAffineTransform()
t.translateX(by: 560, yBy: 600)
t.rotate(byDegrees: 215)   // tip points toward lower-left (the squiggle)
t.concat()
drawPencil()
NSGraphicsContext.restoreGraphicsState()

NSGraphicsContext.restoreGraphicsState()

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_master.png"
let data = rep.representation(using: .png, properties: [:])!
try! data.write(to: URL(fileURLWithPath: outPath))
print("Wrote \(outPath) (\(Int(S))x\(Int(S)))")
