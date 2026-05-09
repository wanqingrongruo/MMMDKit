import Foundation
import MMMDCore

public struct DefaultHTMLRenderer: HTMLRenderer {
    public init() {}

    public func capability(for html: HTMLBlock) -> HTMLRenderCapability {
        let value = html.html.lowercased()

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
