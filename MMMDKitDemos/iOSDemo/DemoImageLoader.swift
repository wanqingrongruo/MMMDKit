import UIKit
import MMMDCore

final class DemoImageLoader: ImageLoader, @unchecked Sendable {
    func loadImageData(from url: URL) async throws -> Data {
        guard url.scheme == "mmmd-demo" else {
            return try Data(contentsOf: url)
        }

        let title = url.lastPathComponent == "architecture" ? "MMMDKit" : "Image Block"
        let subtitle = url.lastPathComponent == "architecture" ? "Parser -> Model -> Native View" : "Local Demo ImageLoader"
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 720, height: 360))
        let image = renderer.image { _ in
            UIColor(red: 0.07, green: 0.12, blue: 0.22, alpha: 1).setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: 720, height: 360)).fill()

            UIColor(red: 0.18, green: 0.42, blue: 0.92, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: 48, y: 56, width: 624, height: 248), cornerRadius: 32).fill()

            UIColor(red: 0.41, green: 0.76, blue: 1, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: 520, y: 36, width: 140, height: 140)).fill()

            (title as NSString).draw(
                in: CGRect(x: 84, y: 104, width: 552, height: 72),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
            )
            (subtitle as NSString).draw(
                in: CGRect(x: 86, y: 188, width: 552, height: 48),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 25, weight: .medium),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.86)
                ]
            )
        }

        guard let data = image.pngData() else {
            throw URLError(.cannotDecodeContentData)
        }
        return data
    }
}
