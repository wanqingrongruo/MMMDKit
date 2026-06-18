import CoreGraphics
import ImageIO
import SwiftUI
import UniformTypeIdentifiers
import XCTest
import MMMDCore
import MMMDParserSwiftMarkdown
import MMMDSwiftUI

final class SwiftUISnapshotTests: XCTestCase {
    @MainActor
    func testMarkdownDocumentViewRendersNonEmptySnapshot() throws {
        guard #available(macOS 13.0, iOS 16.0, *) else {
            throw XCTSkip("SwiftUI ImageRenderer requires macOS 13 / iOS 16.")
        }

        let document = try SwiftMarkdownParser().parse("""
        # Snapshot

        A paragraph with **strong text** and `inline code`.

        ```swift
        let value = 1
        ```
        """)

        let view = MarkdownDocumentView(document: document, configuration: .init())
            .padding(16)
            .frame(width: 360, height: 360, alignment: .topLeading)
            .background(Color.white)
            .environment(\.colorScheme, .light)

        let snapshot = try render(view)
        try assertSnapshot(
            snapshot,
            named: "markdown-document",
            matches: .init(
                width: 360,
                height: 360,
                nonWhitePixels: 800...60_000,
                occupiedRows: 40...260,
                occupiedColumns: 80...360
            )
        )
    }

    @MainActor
    func testLargeTableRendersInsideSnapshotBounds() throws {
        guard #available(macOS 13.0, iOS 16.0, *) else {
            throw XCTSkip("SwiftUI ImageRenderer requires macOS 13 / iOS 16.")
        }

        let rows = (0..<80)
            .map { "| Row \($0) | Value \($0) |" }
            .joined(separator: "\n")
        let document = try SwiftMarkdownParser().parse("""
        | Name | Value |
        | --- | --- |
        \(rows)
        """)
        let configuration = MarkdownConfiguration(
            layoutOptions: .init(tableMaximumVisibleRows: 8, tableMaximumHeight: 180)
        )

        let view = MarkdownDocumentView(document: document, configuration: configuration)
            .padding(16)
            .frame(width: 360, height: 260, alignment: .topLeading)
            .background(Color.white)
            .environment(\.colorScheme, .light)

        let snapshot = try render(view)
        try assertSnapshot(
            snapshot,
            named: "large-table",
            matches: .init(
                width: 360,
                height: 260,
                nonWhitePixels: 400...28_000,
                occupiedRows: 24...240,
                occupiedColumns: 120...360
            )
        )
    }

    @available(macOS 13.0, iOS 16.0, *)
    @MainActor
    private func render<V: View>(_ view: V) throws -> CGImage {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        return try XCTUnwrap(renderer.cgImage)
    }

    private func assertSnapshot(_ image: CGImage, named name: String, matches golden: SnapshotGoldenMetrics) throws {
        try recordOrVerifyPNGFixture(image, named: name)

        let metrics = try snapshotMetrics(in: image)
        XCTAssertEqual(metrics.width, golden.width)
        XCTAssertEqual(metrics.height, golden.height)
        XCTAssertTrue(golden.nonWhitePixels.contains(metrics.nonWhitePixels), "Unexpected non-white pixel count: \(metrics.nonWhitePixels)")
        XCTAssertTrue(golden.occupiedRows.contains(metrics.occupiedRows), "Unexpected occupied row count: \(metrics.occupiedRows)")
        XCTAssertTrue(golden.occupiedColumns.contains(metrics.occupiedColumns), "Unexpected occupied column count: \(metrics.occupiedColumns)")
    }

    private func recordOrVerifyPNGFixture(_ image: CGImage, named name: String) throws {
        let url = snapshotDirectory.appendingPathComponent("\(name).png")
        let shouldRecord = ProcessInfo.processInfo.environment["MMMD_RECORD_SNAPSHOTS"] == "1"

        if shouldRecord {
            try FileManager.default.createDirectory(at: snapshotDirectory, withIntermediateDirectories: true)
            try writePNG(image, to: url)
            return
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "Missing PNG snapshot fixture: \(url.path)")
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let fixture = try loadPNG(from: url)
        XCTAssertEqual(fixture.width, image.width)
        XCTAssertEqual(fixture.height, image.height)
    }

    private var snapshotDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__", isDirectory: true)
    }

    private func writePNG(_ image: CGImage, to url: URL) throws {
        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination), "Failed to write PNG snapshot: \(url.path)")
    }

    private func loadPNG(from url: URL) throws -> CGImage {
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
        return try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
    }

    private func snapshotMetrics(in image: CGImage) throws -> SnapshotMetrics {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        try XCTUnwrap(context).draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var nonWhitePixels = 0
        var occupiedRows = Set<Int>()
        var occupiedColumns = Set<Int>()

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let red = pixels[offset]
                let green = pixels[offset + 1]
                let blue = pixels[offset + 2]
                let alpha = pixels[offset + 3]
                if alpha > 0, red < 245 || green < 245 || blue < 245 {
                    nonWhitePixels += 1
                    occupiedRows.insert(y)
                    occupiedColumns.insert(x)
                }
            }
        }

        return SnapshotMetrics(
            width: width,
            height: height,
            nonWhitePixels: nonWhitePixels,
            occupiedRows: occupiedRows.count,
            occupiedColumns: occupiedColumns.count
        )
    }
}

private struct SnapshotGoldenMetrics {
    var width: Int
    var height: Int
    var nonWhitePixels: ClosedRange<Int>
    var occupiedRows: ClosedRange<Int>
    var occupiedColumns: ClosedRange<Int>
}

private struct SnapshotMetrics {
    var width: Int
    var height: Int
    var nonWhitePixels: Int
    var occupiedRows: Int
    var occupiedColumns: Int
}
