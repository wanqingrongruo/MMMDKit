import XCTest
import MMMDCore
import MMMDParserCmark

final class MarkdownModelTests: XCTestCase {
    func testParserCreatesHeadingParagraphAndCodeBlock() throws {
        let parser = CmarkMarkdownParser()
        let source = """
        # Title

        Body text

        ```swift
        let value = 1
        ```
        """

        let document = try parser.parse(source, options: .init())

        XCTAssertEqual(document.blocks.count, 3)
        XCTAssertEqual(document.blocks.first?.kind, .heading)
        XCTAssertEqual(document.blocks.last?.kind, .code)
    }

    func testPlainTextExtractorFlattensDocument() {
        let document = MarkdownDocument(blocks: [
            .heading(level: 1, content: .init(text: "Title")),
            .paragraph(.init(text: "Body"))
        ])

        XCTAssertEqual(MarkdownTextExtractor.plainText(from: document), "Title\nBody")
    }
}
