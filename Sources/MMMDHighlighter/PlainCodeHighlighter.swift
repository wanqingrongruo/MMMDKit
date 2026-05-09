import Foundation
import MMMDCore

public struct PlainCodeHighlighter: CodeHighlighter {
    public init() {}

    public func highlight(code: String, language: String?, theme: CodeTheme) async throws -> HighlightResult {
        HighlightResult(language: language, tokens: [.init(text: code, scope: nil)])
    }
}
