import Foundation
import MMMDCore

public struct DefaultHTMLRenderer: HTMLRenderer {
    private let sanitizer: HTMLSanitizer

    public init(sanitizer: HTMLSanitizer = .init()) {
        self.sanitizer = sanitizer
    }

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
