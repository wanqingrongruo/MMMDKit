import XCTest
import MMMDCore
import MMMDHighlighter

final class CodeHighlighterTests: XCTestCase {
    func testKeywordHighlighterMarksSwiftKeywords() async throws {
        let highlighter = KeywordCodeHighlighter()

        let result = try await highlighter.highlight(code: "let value = 1", language: "swift", theme: .github)

        XCTAssertTrue(result.tokens.contains(.init(text: "let", scope: "keyword")))
        XCTAssertTrue(result.tokens.contains(.init(text: "1", scope: "number")))
    }

    func testCodeThemeProvidesDefaultTokenStyles() {
        XCTAssertEqual(CodeTheme.github.tokenStyles["keyword"]?.foregroundColor, "systemPurple")
        XCTAssertEqual(CodeTheme.dark.name, "dark")
    }
}
