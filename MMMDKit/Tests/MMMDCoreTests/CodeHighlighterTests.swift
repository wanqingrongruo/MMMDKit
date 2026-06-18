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

    func testCachingHighlighterReusesMatchingResult() async throws {
        let base = CountingHighlighter()
        let highlighter = CachingCodeHighlighter(base: base)

        let first = try await highlighter.highlight(code: "let value = 1", language: "swift", theme: .github)
        let second = try await highlighter.highlight(code: "let value = 1", language: "Swift", theme: .github)

        XCTAssertEqual(first, second)
        let invocationCount = await base.invocationCount
        XCTAssertEqual(invocationCount, 1)
    }

    func testCachingHighlighterSeparatesThemeChanges() async throws {
        let base = CountingHighlighter()
        let highlighter = CachingCodeHighlighter(base: base)

        _ = try await highlighter.highlight(code: "let value = 1", language: "swift", theme: .github)
        _ = try await highlighter.highlight(code: "let value = 1", language: "swift", theme: .dark)

        let invocationCount = await base.invocationCount
        XCTAssertEqual(invocationCount, 2)
    }
}

private actor CountingHighlighter: CodeHighlighter {
    private var count = 0

    var invocationCount: Int {
        count
    }

    func highlight(code: String, language: String?, theme: CodeTheme) async throws -> HighlightResult {
        count += 1
        return HighlightResult(language: language, tokens: [.init(text: code, scope: theme.name)])
    }
}
