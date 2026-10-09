import Cocoa

let size = CGSize(width: 560, height: 340)
let image = NSImage(size: size)
image.lockFocus()

// Draw background (light neutral)
NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.97, alpha: 1.0).setFill()
NSRect(origin: .zero, size: size).fill()

// Draw arrow in center (pointing right)
// Note: NSImage coordinates start at bottom-left
let path = NSBezierPath()
path.move(to: CGPoint(x: 240, y: 160))
path.line(to: CGPoint(x: 300, y: 160))
path.line(to: CGPoint(x: 300, y: 145))
path.line(to: CGPoint(x: 330, y: 170))
path.line(to: CGPoint(x: 300, y: 195))
path.line(to: CGPoint(x: 300, y: 180))
path.line(to: CGPoint(x: 240, y: 180))
path.close()

NSColor(calibratedRed: 0.7, green: 0.72, blue: 0.74, alpha: 1.0).setFill()
path.fill()

// Draw text "Drag to Install"
let text = "Drag to Install" as NSString
let font = NSFont.systemFont(ofSize: 15, weight: .medium)
let textColor = NSColor(calibratedRed: 0.5, green: 0.52, blue: 0.54, alpha: 1.0)
let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.alignment = .center

let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: textColor,
    .paragraphStyle: paragraphStyle
]

// Position text below the arrow. Y=120 means bottom-up, so it's below center (170)
let textRect = NSRect(x: 0, y: 110, width: 560, height: 30)
text.draw(in: textRect, withAttributes: attributes)

image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not generate PNG data")
}

let url = URL(fileURLWithPath: "scripts/dmg_background.png")
try! pngData.write(to: url)
print("Generated scripts/dmg_background.png")
