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

    func testParserPreservesBlockSourceRanges() throws {
        let parser = CmarkMarkdownParser()
        let source = """
        # Title

        Body text
        continues
        """

        let document = try parser.parse(source, options: .init())

        XCTAssertEqual(document.blockSourceRanges.count, document.blocks.count)
        XCTAssertEqual(document.blockSourceRanges[0], .init(startLine: 1, startColumn: 1, endLine: 1, endColumn: 8))
        XCTAssertEqual(document.blockSourceRanges[1], .init(startLine: 3, startColumn: 1, endLine: 4, endColumn: 10))
    }

    func testParserCreatesEmphasisAndStrongInlineNodes() throws {
        let parser = CmarkMarkdownParser()
        let document = try parser.parse("Hello *em* and **strong**", options: .init())

        guard case .paragraph(let content) = document.blocks.first else {
            return XCTFail("Expected paragraph block")
        }

        XCTAssertEqual(content.nodes, [
            .text("Hello "),
            .emphasis([.text("em")]),
            .text(" and "),
            .strong([.text("strong")])
        ])
    }

    func testParserCreatesLinkInlineNode() throws {
        let parser = CmarkMarkdownParser()
        let document = try parser.parse("Open [GitHub](https://github.com)", options: .init())

        guard case .paragraph(let content) = document.blocks.first else {
            return XCTFail("Expected paragraph block")
        }

        XCTAssertEqual(content.nodes, [
            .text("Open "),
            .link(text: [.text("GitHub")], url: URL(string: "https://github.com"))
        ])
    }

    func testParserCreatesUnorderedListBlock() throws {
        let parser = CmarkMarkdownParser()
        let document = try parser.parse("""
        - First
        - Second
        """, options: .init())

        guard case .list(let list) = document.blocks.first else {
            return XCTFail("Expected list block")
        }

        XCTAssertEqual(list.style, .unordered)
        XCTAssertEqual(list.items.count, 2)
        XCTAssertEqual(MarkdownTextExtractor.plainText(from: list.items[0].blocks[0]), "First")
    }

    func testParserCreatesOrderedListBlock() throws {
        let parser = CmarkMarkdownParser()
        let document = try parser.parse("""
        3. Third
        4. Fourth
        """, options: .init())

        guard case .list(let list) = document.blocks.first else {
            return XCTFail("Expected list block")
        }

        XCTAssertEqual(list.style, .ordered(start: 3))
        XCTAssertEqual(list.items.count, 2)
    }

    func testParserCreatesBlockquoteBlock() throws {
        let parser = CmarkMarkdownParser()
        let document = try parser.parse("""
        > Quote
        > continues
        """, options: .init())

        guard case .blockquote(let blocks) = document.blocks.first else {
            return XCTFail("Expected blockquote block")
        }

        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(MarkdownTextExtractor.plainText(from: blocks[0]), "Quote\ncontinues")
    }

    func testParserCreatesTableBlock() throws {
        let parser = CmarkMarkdownParser()
        let document = try parser.parse("""
        | Name | Age |
        | --- | --- |
        | Amy | 5 |
        """, options: .init())

        guard case .table(let table) = document.blocks.first else {
            return XCTFail("Expected table block")
        }

        XCTAssertEqual(table.header.map(MarkdownTextExtractor.plainText(from:)), ["Name", "Age"])
        XCTAssertEqual(table.rows.count, 1)
        XCTAssertEqual(table.rows[0].map(MarkdownTextExtractor.plainText(from:)), ["Amy", "5"])
    }

    func testParserCreatesInlineMathNode() throws {
        let parser = CmarkMarkdownParser()
        let document = try parser.parse("公式 $x^2$", options: .init())

        guard case .paragraph(let content) = document.blocks.first else {
            return XCTFail("Expected paragraph block")
        }

        XCTAssertEqual(content.nodes, [.text("公式 "), .math("x^2")])
    }

    func testParserCreatesDisplayMathBlock() throws {
        let parser = CmarkMarkdownParser()
        let document = try parser.parse("""
        $$
        x^2 + y^2
        $$
        """, options: .init())

        guard case .math(let math) = document.blocks.first else {
            return XCTFail("Expected math block")
        }

        XCTAssertTrue(math.displayMode)
        XCTAssertEqual(math.latex, "x^2 + y^2")
    }

    func testParserCreatesImageBlock() throws {
        let parser = CmarkMarkdownParser()
        let document = try parser.parse("![Diagram](mmmd-demo://image/architecture)", options: .init())

        guard case .image(let image) = document.blocks.first else {
            return XCTFail("Expected image block")
        }

        XCTAssertEqual(image.alt, "Diagram")
        XCTAssertEqual(image.url, URL(string: "mmmd-demo://image/architecture"))
    }

    func testParserKeepsInlineImageInParagraph() throws {
        let parser = CmarkMarkdownParser()
        let document = try parser.parse("查看 ![Preview](mmmd-demo://image/preview) 图片", options: .init())

        guard case .paragraph(let content) = document.blocks.first else {
            return XCTFail("Expected paragraph block")
        }

        XCTAssertEqual(content.nodes, [
            .text("查看 "),
            .image(alt: "Preview", url: URL(string: "mmmd-demo://image/preview")),
            .text(" 图片")
        ])
    }

    func testCopyPayloadUsesOriginalMarkdownSource() throws {
        let parser = CmarkMarkdownParser()
        let source = "# Title"
        let document = try parser.parse(source, options: .init())

        let payload = CopyPayloadBuilder.payload(for: document)

        XCTAssertEqual(payload.plainText, "Title")
        XCTAssertEqual(payload.markdown, source)
    }

    func testCodeBlockCopyPayloadPreservesFence() {
        let payload = CopyPayloadBuilder.payload(for: CodeBlock(language: "swift", content: "let value = 1"))

        XCTAssertEqual(payload.plainText, "let value = 1")
        XCTAssertEqual(payload.markdown, "```swift\nlet value = 1\n```")
    }
}
