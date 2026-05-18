import AppKit
import MMMDCore

final class DemoImageLoader: ImageLoader, @unchecked Sendable {
    func loadImageData(from url: URL) async throws -> Data {
        guard url.scheme == "mmmd-demo" else {
            return try Data(contentsOf: url)
        }

        let title = url.lastPathComponent == "architecture" ? "MMMDKit" : "Image Block"
        let subtitle = url.lastPathComponent == "architecture" ? "Parser -> Model -> Native View" : "Local Demo ImageLoader"
        let image = NSImage(size: NSSize(width: 720, height: 360))
        image.lockFocus()
        NSColor(red: 0.07, green: 0.12, blue: 0.22, alpha: 1).setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 720, height: 360)).fill()

        NSColor(red: 0.18, green: 0.42, blue: 0.92, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 48, y: 56, width: 624, height: 248), xRadius: 32, yRadius: 32).fill()

        NSColor(red: 0.41, green: 0.76, blue: 1, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: 520, y: 184, width: 140, height: 140)).fill()

        (title as NSString).draw(
            in: NSRect(x: 84, y: 184, width: 552, height: 72),
            withAttributes: [
                .font: NSFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: NSColor.white
            ]
        )
        (subtitle as NSString).draw(
            in: NSRect(x: 86, y: 124, width: 552, height: 48),
            withAttributes: [
                .font: NSFont.systemFont(ofSize: 25, weight: .medium),
                .foregroundColor: NSColor.white.withAlphaComponent(0.86)
            ]
        )
        image.unlockFocus()

        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            throw URLError(.cannotDecodeContentData)
        }
        return pngData
    }
}
