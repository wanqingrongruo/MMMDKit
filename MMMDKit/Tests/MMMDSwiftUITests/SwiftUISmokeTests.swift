import XCTest
import MMMDCore
import MMMDParserSwiftMarkdown
import MMMDSwiftUI

final class SwiftUISmokeTests: XCTestCase {
    func testMarkdownTextCanBeConstructedWithDefaultParser() {
        _ = MarkdownText("# Hello\n\nSwiftUI **Markdown**")
        XCTAssertTrue(true)
    }

    func testMarkdownDocumentViewCanRenderParsedDocument() throws {
        let document = try SwiftMarkdownParser().parse("""
        # Hello

        | A | B |
        | --- | --- |
        | 1 | 2 |
        """)

        _ = MarkdownDocumentView(document: document, configuration: .init())
        XCTAssertEqual(document.blocks.count, 2)
    }

    func testStreamingMarkdownTextCanUseDeltaSource() {
        let source = AsyncStream<String> { continuation in
            continuation.yield("# Hello\n\n")
            continuation.yield("Streaming")
            continuation.finish()
        }

        _ = StreamingMarkdownText(source: source, inputMode: .delta)
        XCTAssertTrue(true)
    }
}
