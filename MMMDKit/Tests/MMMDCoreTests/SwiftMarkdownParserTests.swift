import XCTest
import MMMDCore
import MMMDParserSwiftMarkdown

final class SwiftMarkdownParserTests: XCTestCase {
    private let parser = SwiftMarkdownParser()

    func testSwiftMarkdownParserCreatesCommonBlocks() throws {
        let document = try parser.parse("""
        # Title

        Hello **world** with [link](https://example.com).

        ```swift
        print("hi")
        ```
        """)

        XCTAssertEqual(document.blocks.count, 3)
        XCTAssertEqual(document.blocks.first?.kind, .heading)
        XCTAssertEqual(document.blocks.last?.kind, .code)
    }

    func testSwiftMarkdownParserCreatesTable() throws {
        let document = try parser.parse("""
        | Name | Value | Score |
        | :--- | ---: | :---: |
        | A | 1 |
        """)

        guard case .table(let table) = document.blocks.first else {
            return XCTFail("Expected table")
        }
        XCTAssertEqual(table.header.count, 3)
        XCTAssertEqual(table.columnAlignments, [.leading, .trailing, .center])
        XCTAssertEqual(table.rows.count, 1)
    }

    func testSwiftMarkdownParserCreatesMathBlocksAndInlineMath() throws {
        let document = try parser.parse("""
        Inline \\(x + y\\).

        $$
        E = mc^2
        $$
        """)

        guard case .paragraph(let paragraph) = document.blocks.first else {
            return XCTFail("Expected paragraph")
        }
        XCTAssertTrue(paragraph.nodes.contains(.math("x + y")))
        XCTAssertEqual(document.blocks.last?.kind, .math)
    }

    func testSwiftMarkdownParserCreatesSingleLineDisplayMath() throws {
        let document = try parser.parse("$$a^2 + b^2 = c^2$$")

        guard case .math(let math) = document.blocks.first else {
            return XCTFail("Expected math block")
        }

        XCTAssertTrue(math.displayMode)
        XCTAssertEqual(math.latex, "a^2 + b^2 = c^2")
    }

    func testSwiftMarkdownParserPreservesDeepNestedLists() throws {
        let document = try parser.parse("""
        - Top level item 1
          - Nested item A
            - Deeply nested item X
            - Deeply nested item Y
          - Nested item B
        - Top level item 2
          - Nested item C
        """)

        guard case .list(let topList) = document.blocks.first else {
            return XCTFail("Expected top-level list")
        }

        XCTAssertEqual(topList.items.count, 2)
        XCTAssertEqual(MarkdownTextExtractor.plainText(from: topList.items[0].blocks[0]), "Top level item 1")

        guard topList.items[0].blocks.count > 1,
              case .list(let nestedList) = topList.items[0].blocks[1] else {
            return XCTFail("Expected nested list under first item")
        }

        XCTAssertEqual(nestedList.items.count, 2)
        XCTAssertEqual(MarkdownTextExtractor.plainText(from: nestedList.items[0].blocks[0]), "Nested item A")

        guard nestedList.items[0].blocks.count > 1,
              case .list(let deepList) = nestedList.items[0].blocks[1] else {
            return XCTFail("Expected deeply nested list under nested item")
        }

        XCTAssertEqual(deepList.items.count, 2)
        XCTAssertEqual(MarkdownTextExtractor.plainText(from: deepList.items[1].blocks[0]), "Deeply nested item Y")
    }

    func testSpeculativeRewriteClosesStreamingCodeFence() throws {
        let document = try parser.parse("""
        ```swift
        let value = 1
        """, options: .init(speculativeRewrite: true))

        XCTAssertEqual(document.blocks.first?.kind, .code)
    }
}
