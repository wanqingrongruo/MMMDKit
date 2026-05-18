import Foundation
import MMMDCore

/// 不做语法分析的纯文本代码高亮器。
///
/// 适合用作默认 fallback，保证代码块仍以等宽文本显示。
public struct PlainCodeHighlighter: CodeHighlighter {
    public init() {}

    /// 返回单个无 scope 的 token。
    public func highlight(code: String, language: String?, theme: CodeTheme) async throws -> HighlightResult {
        HighlightResult(language: language, tokens: [.init(text: code, scope: nil)])
    }
}
