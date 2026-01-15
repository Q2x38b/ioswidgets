#!/usr/bin/env swift

import Cocoa
import CoreGraphics

// Create a 1024x1024 app icon - Calendar style for Stride
let size = CGSize(width: 1024, height: 1024)
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

guard let context = CGContext(
    data: nil,
    width: Int(size.width),
    height: Int(size.height),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: bitmapInfo.rawValue
) else {
    print("Failed to create context")
    exit(1)
}

// Background gradient (dark grey)
let gradientColors = [
    CGColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0),
    CGColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0)
] as CFArray

let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: gradientColors,
    locations: [0.0, 1.0]
)!

// Fill background
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: size.height),
    end: CGPoint(x: size.width, y: 0),
    options: []
)

// Calendar accent color (grey)
let accentColor = CGColor(red: 0.55, green: 0.55, blue: 0.60, alpha: 1.0)
let lightAccent = CGColor(red: 0.65, green: 0.65, blue: 0.70, alpha: 1.0)

// Draw calendar outline
context.setStrokeColor(accentColor)
context.setLineWidth(40)
context.setLineCap(.round)
context.setLineJoin(.round)

// Calendar body - rounded rectangle
let calendarRect = CGRect(x: 180, y: 150, width: 664, height: 620)
let calendarPath = CGPath(roundedRect: calendarRect, cornerWidth: 60, cornerHeight: 60, transform: nil)
context.addPath(calendarPath)
context.strokePath()

// Calendar top bar (header) - filled
context.setFillColor(accentColor)
let headerPath = CGMutablePath()
headerPath.move(to: CGPoint(x: 180, y: 620))
headerPath.addLine(to: CGPoint(x: 180, y: 710))
headerPath.addQuadCurve(to: CGPoint(x: 240, y: 770), control: CGPoint(x: 180, y: 770))
headerPath.addLine(to: CGPoint(x: 784, y: 770))
headerPath.addQuadCurve(to: CGPoint(x: 844, y: 710), control: CGPoint(x: 844, y: 770))
headerPath.addLine(to: CGPoint(x: 844, y: 620))
headerPath.closeSubpath()
context.addPath(headerPath)
context.fillPath()

// Calendar rings/hooks
context.setStrokeColor(lightAccent)
context.setLineWidth(36)
context.setLineCap(.round)

// Left hook
context.move(to: CGPoint(x: 340, y: 820))
context.addLine(to: CGPoint(x: 340, y: 720))
context.strokePath()

// Right hook
context.move(to: CGPoint(x: 684, y: 820))
context.addLine(to: CGPoint(x: 684, y: 720))
context.strokePath()

// Draw grid lines (calendar days hint)
context.setStrokeColor(CGColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 0.5))
context.setLineWidth(3)

// Horizontal lines
for i in 1...3 {
    let y = 150 + CGFloat(i) * 117
    context.move(to: CGPoint(x: 220, y: y))
    context.addLine(to: CGPoint(x: 804, y: y))
}

// Vertical lines
for i in 1...4 {
    let x = 180 + CGFloat(i) * 133
    context.move(to: CGPoint(x: x, y: 190))
    context.addLine(to: CGPoint(x: x, y: 580))
}
context.strokePath()

// Draw a checkmark in one cell to indicate task completion
context.setStrokeColor(lightAccent)
context.setLineWidth(28)
context.setLineCap(.round)
context.setLineJoin(.round)

let checkPath = CGMutablePath()
checkPath.move(to: CGPoint(x: 270, y: 420))
checkPath.addLine(to: CGPoint(x: 320, y: 370))
checkPath.addLine(to: CGPoint(x: 420, y: 480))

context.addPath(checkPath)
context.strokePath()

// Create image
guard let cgImage = context.makeImage() else {
    print("Failed to create image")
    exit(1)
}

let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: size.width, height: size.height))
guard let tiffData = nsImage.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to convert to PNG")
    exit(1)
}

// Save to file
let outputPath = "/Volumes/Macintosh_HD/Users/user289590/Documents/ioswidgets/MinimalTodo/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
do {
    try pngData.write(to: URL(fileURLWithPath: outputPath))
    print("Calendar icon saved to \(outputPath)")
} catch {
    print("Failed to save: \(error)")
    exit(1)
}
