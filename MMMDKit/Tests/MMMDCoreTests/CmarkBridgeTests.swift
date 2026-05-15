import XCTest
import MMMDCore
@testable import MMMDParserCmark

final class CmarkBridgeTests: XCTestCase {
    func testParserUsesInjectedBridgeEngine() throws {
        let engine = StubCmarkParsingEngine()
        let parser = CmarkMarkdownParser(bridge: CmarkBridge(engine: engine))

        let document = try parser.parse("ignored", options: .init())

        XCTAssertEqual(document.blocks.count, 1)
        XCTAssertEqual(MarkdownTextExtractor.plainText(from: document), "Bridge")
    }
}

private struct StubCmarkParsingEngine: CmarkParsingEngine {
    func parse(_ source: String, options: ParseOptions) throws -> CmarkNode {
        CmarkNode(type: .document, children: [
            .init(type: .heading(level: 2), children: [
                .init(type: .text("Bridge"))
            ])
        ])
    }
}
