import Foundation
import MMMDCore

/// 默认 HTML 渲染能力判断器。
///
/// 它不会直接创建 UI，而是根据 HTML 内容判断更适合原生行内、原生块、WebView fallback
/// 还是直接标记为不支持。
public struct DefaultHTMLRenderer: HTMLRenderer {
    private let sanitizer: HTMLSanitizer

    public init(sanitizer: HTMLSanitizer = .init()) {
        self.sanitizer = sanitizer
    }

    /// 判断一段 HTML 块适合使用哪种渲染策略。
    public func capability(for html: HTMLBlock) -> HTMLRenderCapability {
        let value = sanitizer.sanitize(html.html).lowercased()

        if value.contains("<script") {
            return .unsupported
        }

        if value.contains("<table") || value.contains("<iframe") || value.contains("<style") {
            return .webViewFallback
        }

        if value.contains("<br") || value.contains("<span") || value.contains("<sup") || value.contains("<sub") {
            return .nativeInline
        }

        return .nativeBlock
    }
}
